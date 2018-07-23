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

require 'factory_bot_caching/config'

describe FactoryBotCaching::Config do
  describe '#cache_timeout' do
    it 'defaults to 15 minutes (900 seconds)' do
      expect(subject.cache_timeout).to eq 900
    end
    it 'can be set to a custom value' do
      subject.cache_timeout = 300
      expect(subject.cache_timeout).to eq 300
    end
    it 'raises if a non-integer value is given' do
      expect {
        subject.cache_timeout = 'foo'
      }.to raise_error ArgumentError, 'Cache timeout must be an Integer!'
    end
  end

  describe '#factory_caching_enabled' do
    it 'is disabled by default' do
      expect(subject.factory_caching_enabled).to be false
    end
    it 'returns true when caching is enabled' do
      subject.enable_factory_caching
      expect(subject.factory_caching_enabled).to be true
    end
  end

  describe '#factory_caching_enabled?' do
    it 'is disabled by default' do
      expect(subject.factory_caching_enabled?).to be false
    end

    it 'returns true when caching is enabled' do
      subject.enable_factory_caching
      expect(subject.factory_caching_enabled?).to be true
    end
  end

  describe '#enable_factory_caching' do
    it 'enables factory caching' do
      expect {
        subject.enable_factory_caching
      }.to change { subject.factory_caching_enabled? }.from(false).to(true)
    end
  end

  describe '#disable_factory_caching' do
    it 'disables factory caching' do
      subject.enable_factory_caching
      expect {
        subject.disable_factory_caching
      }.to change { subject.factory_caching_enabled? }.from(true).to(false)
    end
  end

  describe '#custom_cache_key=' do
    it 'adds additional caching layers' do
      cache_key_proc = -> { :foo }
      subject.custom_cache_key = cache_key_proc
      expect(subject.custom_cache_key).to be cache_key_proc
    end

    it 'raises if the cache key is not a proc' do
      expect {
        subject.custom_cache_key = 'foo'
      }.to raise_error(ArgumentError, 'The custom cache key must be a Proc!')
    end
  end
end
