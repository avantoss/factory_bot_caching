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

require_relative 'factory_cache'

module FactoryBotCaching
  class CacheManager
    def self.instance
      @instance ||= self.new
    end

    def initialize
      @factory_cache = Hash.new do |hash, key|
        hash[key] = FactoryCache.new(factory_name: key)
      end
    end

    def reset_cache
      factory_cache.each_value(&:reset)
    end

    def reset_cache_counter
      factory_cache.each_value(&:reset_counter)
    end

    def fetch(name:, overrides:, traits:, &block)
      factory_cache[name].fetch(overrides: overrides, traits: traits, &block)
    end

    private

    attr_reader :factory_cache
  end
end
