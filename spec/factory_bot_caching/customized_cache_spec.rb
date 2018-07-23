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

require 'factory_bot_caching/customized_cache'

describe FactoryBotCaching::CustomizedCache do
  let(:build_class) { Class.new }
  let(:cache_key_generator) { instance_double(Proc, call: 1) }

  subject { described_class.new(build_class: build_class, cache_key_generator: cache_key_generator) }

  let(:record_cache_class) { FactoryBotCaching::FactoryRecordCache }
  let(:cache_1) { instance_double(record_cache_class, fetch: 1, reset_counters: nil) }
  let(:cache_2) { instance_double(record_cache_class, fetch: 2, reset_counters: nil) }

  before do
    allow(record_cache_class).to receive(:new) do
      cache_key_generator.call == 1 ? cache_1 : cache_2
    end
  end

  describe '#reset_cache_counter' do
    it 'resets the cache counter on all customized factory caches' do
      subject.fetch(overrides: [], traits: [])

      allow(cache_key_generator).to receive(:call).and_return(2)
      subject.fetch(overrides: [], traits: [])

      subject.reset_counters

      expect(cache_1).to have_received(:reset_counters).once
      expect(cache_2).to have_received(:reset_counters).once
    end
  end

  describe '#fetch' do
    it 'lazily instantiates a new cache on the first call to fetch when the cache key changes' do
      subject.fetch(overrides: [], traits: [])
      subject.fetch(overrides: [], traits: [])

      allow(cache_key_generator).to receive(:call).and_return(2)
      subject.fetch(overrides: [], traits: [])
      subject.fetch(overrides: [], traits: [])

      expect(record_cache_class).to have_received(:new).with(build_class: build_class).twice
    end

    it 'fetches the record from the factory cache for the current cache key' do
      cache_1_result = subject.fetch(overrides: [1], traits: [:a])
      expect(cache_1_result).to eq 1

      allow(cache_key_generator).to receive(:call).and_return(2)
      cache_2_result = subject.fetch(overrides: [2], traits: [:b, :c])
      expect(cache_2_result).to eq 2
    end

    it 'passes the block forward to execute if no cached factory exists' do
      allow(cache_1).to receive(:fetch).with(overrides: [1], traits: [:a]).and_yield
      block_result = subject.fetch(overrides: [1], traits: [:a]) { 'a factory block result' }

      expect(block_result).to eq 'a factory block result'
    end
  end
end
