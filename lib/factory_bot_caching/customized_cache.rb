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

require_relative 'factory_record_cache'
require 'i18n'

module FactoryBotCaching
  class CustomizedCache
    def initialize(build_class:, cache_key_generator:)
      @cache_key_generator = cache_key_generator
      @cache = Hash.new do |hash, key|
        hash[key] = FactoryRecordCache.new(build_class: build_class)
      end
    end

    def fetch(overrides:, traits:, &block)
      customized_cache.fetch(overrides: overrides, traits: traits, &block)
    end

    def reset_counters
      cache.each_value(&:reset_counters)
    end

    private

    attr_reader :cache, :cache_key_generator

    def customized_cache
      key = cache_key_generator.call
      cache[key]
    end
  end
end
