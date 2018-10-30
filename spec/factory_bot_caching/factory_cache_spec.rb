# The MIT License (MIT)
#
# Copyright (c) 2017-2018 Avant
#
# Author Tim Mertens
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'factory_bot_caching/factory_cache'
require 'active_record'
require 'factory_bot'

describe FactoryBotCaching::FactoryCache do
  subject { described_class.new(factory_name: :thingy) }

  let(:build_class) do
    build_class = Class.new(ActiveRecord::Base) do
      # This prevents errors from being raised when the stub below is made and rails_helper has been loaded.  AR blows
      # up because there is no actual table for this class.
      def self.define_attribute_methods
        nil
      end
    end
    allow(build_class).to receive(:reflect_on_all_associations).and_return(associations)
    build_class
  end

  let(:associations) do
    [
      instance_double(ActiveRecord::Reflection::BelongsToReflection, macro: :belongs_to, foreign_key: 'lion_id', name: 'lion'),
      instance_double(ActiveRecord::Reflection::HasAndBelongsToManyReflection, macro: :has_and_belongs_to_many, name: 'tigers'),
      instance_double(ActiveRecord::Reflection::ThroughReflection, macro: :has_many, name: :bears),
      instance_double(ActiveRecord::Reflection::HasManyReflection, macro: :has_many, name: 'sandwiches'),
      instance_double(ActiveRecord::Reflection::HasOneReflection, macro: :has_one, name: :horse)
    ]
  end

  let(:cache)   { instance_double(FactoryBotCaching::CustomizedCache, reset_counters: nil, fetch: 'cached response 1') }
  let(:cache_2) { instance_double(FactoryBotCaching::CustomizedCache, reset_counters: nil, fetch: 'cached response 2') }
  let(:factory_block) do
    -> {
      'return value of the actual factory block'
    }
  end
  let(:custom_cache_key) { nil }

  before do
    factory = instance_double(FactoryBot::Factory, build_class: build_class)
    allow(FactoryBot).to receive(:factory_by_name).with(:thingy).and_return(factory)
    allow(FactoryBotCaching.configuration).to receive(:custom_cache_key).and_return(custom_cache_key)
    allow(FactoryBotCaching::CustomizedCache).to receive(:new).with(build_class: build_class, cache_key_generator: custom_cache_key).and_return(cache, cache_2)
    allow(FactoryBotCaching::FactoryRecordCache).to receive(:new).with(build_class: build_class).and_return(cache, cache_2)
  end

  context 'without a custom cache key' do
    it 'does NOT wrap the FactoryRecordCache in a CustomizedCache' do
      subject
      expect(FactoryBotCaching::FactoryRecordCache).to have_received(:new).with(build_class: build_class)
    end
  end

  context 'with a custom cache key' do
    let(:custom_cache_key) { -> { 1 } }

    it 'wraps the FactoryRecordCache in a CustomizedCache' do
      subject
      expect(FactoryBotCaching::FactoryRecordCache).not_to have_received(:new)
      expect(FactoryBotCaching::CustomizedCache).to have_received(:new).with(build_class: build_class, cache_key_generator: custom_cache_key)
    end
  end

  describe '#reset' do
    it 'creates a new cache' do
      expect do
        subject.reset
      end.to change { subject.fetch(overrides: [], traits: [], &factory_block) }
               .from('cached response 1')
               .to('cached response 2')
    end
  end

  describe '#reset_counter' do
    it 'resets counters on the cache' do
      subject.reset_counter
      expect(cache).to have_received(:reset_counters)
    end
  end

  describe '#fetch' do
    it 'fetches from the cache when caching is enabled and there are no uncachable overrides' do
      result = subject.fetch(overrides: [], traits: [], &factory_block)
      expect(result).to eq 'cached response 1'
    end

    it 'bypasses the cache when there are overrides for belongs_to associations by name' do
      result = subject.fetch(overrides: {lion: 1}, traits: [], &factory_block)
      expect(result).to eq 'return value of the actual factory block'
    end

    it 'bypasses the cache when there are overrides for belongs_to associations by foreign_key' do
      result = subject.fetch(overrides: {lion_id: 1}, traits: [], &factory_block)
      expect(result).to eq 'return value of the actual factory block'
    end

    it 'bypasses the cache when there are overrides for has_and_belongs_to_many associations' do
      result = subject.fetch(overrides: {tigers: []}, traits: [], &factory_block)
      expect(result).to eq 'return value of the actual factory block'
    end

    it 'bypasses the cache when there are overrides for through associations' do
      result = subject.fetch(overrides: {bears: []}, traits: [], &factory_block)
      expect(result).to eq 'return value of the actual factory block'
    end

    it 'bypasses the cache when there are overrides for has_many associations' do
      result = subject.fetch(overrides: {sandwiches: []}, traits: [], &factory_block)
      expect(result).to eq 'return value of the actual factory block'
    end

    it 'bypasses the cache when there are overrides for has_one associations' do
      result = subject.fetch(overrides: {horse: 1}, traits: [], &factory_block)
      expect(result).to eq 'return value of the actual factory block'
    end

    context 'build classes that are not a descendant of ActiveRecord::Base' do
      let(:build_class) { Class.new }

      it 'bypasses the cache when the build class is not a descendant of ActiveRecord::Base' do
        result = subject.fetch(overrides: [], traits: [], &factory_block)
        expect(result).to eq 'return value of the actual factory block'
      end
    end
  end
end
