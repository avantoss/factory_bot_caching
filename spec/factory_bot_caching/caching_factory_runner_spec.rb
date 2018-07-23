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

require 'factory_bot_caching/caching_factory_runner'

describe FactoryBotCaching::CachingFactoryRunner do
  subject do
    test_class = Class.new do
      def initialize
        @name      = 'MyFactory'
        @overrides = [1, 3, 5]
        @traits    = [2, 4, 6]
      end

      def run(_runner_strategy, &block)
        block.call
      end
    end
    test_class.prepend described_class
    test_class.new
  end

  let(:manager)      { instance_double(FactoryBotCaching::CacheManager, reset_cache_counter: nil) }
  let(:expected_key) { { name: 'MyFactory', overrides: [1, 3, 5], traits: [2, 4, 6] } }

  before do
    allow(FactoryBotCaching::CacheManager).to receive(:instance).and_return(manager)
  end

  describe '#run' do
    it 'fetches a cached record if possible' do
      allow(FactoryBotCaching).to receive(:enabled?).and_return(true)
      allow(manager).to receive(:fetch).with(expected_key).and_return('foo')

      result = subject.run(:create) { 'bar' }

      expect(result).to eq 'foo'
    end

    it 'yields the factory result if no cached record exists' do
      allow(FactoryBotCaching).to receive(:enabled?).and_return(true)
      allow(manager).to receive(:fetch).with(expected_key).and_yield

      result = subject.run(:create) { 'bar' }
      expect(result).to eq 'bar'
    end

    it 'yields the factory result if factory caching is disabled' do
      allow(FactoryBotCaching).to receive(:enabled?).and_return(false)

      result = subject.run(:create) { 'bar' }
      expect(result).to eq 'bar'
    end

    it 'yields the factory result if factory strategy is not create' do
      allow(FactoryBotCaching).to receive(:enabled?).and_return(true)

      result = subject.run(:build) { 'bar' }
      expect(result).to eq 'bar'
    end
  end
end
