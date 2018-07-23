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

require 'factory_bot_caching/cache_manager'

describe FactoryBotCaching::CacheManager do
  subject { described_class.new }

  let(:cache_class) { FactoryBotCaching::FactoryCache }
  let(:foo_cache) { instance_double(FactoryBotCaching::FactoryCache,
                                    factory_name:  :foo,
                                    fetch:         'foo instance',
                                    reset:         nil,
                                    reset_counter: nil) }
  let(:bar_cache) { instance_double(FactoryBotCaching::FactoryCache,
                                    factory_name:  :bar,
                                    fetch:         'bar instance',
                                    reset:         nil,
                                    reset_counter: nil) }

  before do
    allow(cache_class).to receive(:new).with(factory_name: :foo).and_return(foo_cache)
    allow(cache_class).to receive(:new).with(factory_name: :bar).and_return(bar_cache)
  end

  describe '.instance' do
    it 'returns a singleton instance' do
      instance = described_class.instance
      expect(described_class.instance).to be instance
    end
  end

  describe '#reset_cache_counter' do
    it 'resets the cache counter on all factory caches' do
      subject.fetch(name: :foo, overrides: [], traits: [])
      subject.fetch(name: :bar, overrides: [], traits: [])

      subject.reset_cache_counter

      expect(foo_cache).to have_received(:reset_counter).once
      expect(bar_cache).to have_received(:reset_counter).once
    end
  end

  describe '#reset_cache' do
    it 'resets all factory caches' do
      subject.fetch(name: :foo, overrides: [], traits: [])
      subject.fetch(name: :bar, overrides: [], traits: [])

      subject.reset_cache

      expect(foo_cache).to have_received(:reset).once
      expect(bar_cache).to have_received(:reset).once
    end
  end

  describe '#fetch' do
    it 'fetches the record from the designated factory cache' do
      foo_result = subject.fetch(name: :foo, overrides: [1], traits: [:a])
      bar_result = subject.fetch(name: :bar, overrides: [2], traits: [:b, :c])

      expect(foo_result).to eq 'foo instance'
      expect(bar_result).to eq 'bar instance'
      expect(foo_cache).to have_received(:fetch).with(overrides: [1], traits: [:a])
      expect(bar_cache).to have_received(:fetch).with(overrides: [2], traits: [:b, :c])
    end

    it 'passes the block forward to execute if no cached factory exists' do
      allow(foo_cache).to receive(:fetch).with(overrides: [1], traits: [:a]).and_yield
      foo_result = subject.fetch(name: :foo, overrides: [1], traits: [:a]) { 'a factory block result' }

      expect(foo_result).to eq 'a factory block result'
    end

    it 'creates a new FactoryCache for each named factory on the first call for a given name' do
      subject.fetch(name: :foo, overrides: [1], traits: [])
      subject.fetch(name: :foo, overrides: [2], traits: [])
      subject.fetch(name: :foo, overrides: [3], traits: [])
      subject.fetch(name: :bar, overrides: [1], traits: [])
      subject.fetch(name: :bar, overrides: [2], traits: [])

      expect(cache_class).to have_received(:new).with(factory_name: :foo).once
      expect(cache_class).to have_received(:new).with(factory_name: :bar).once
    end
  end
end
