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

module FactoryBotCaching
  class Config
    FIFTEEN_MINUTES_IN_SECONDS = 900

    def initialize
      @factory_caching_enabled = false
      @custom_cache_key = nil
      @cache_timeout = FIFTEEN_MINUTES_IN_SECONDS
    end

    attr_reader :factory_caching_enabled, :custom_cache_key, :cache_timeout
    alias_method :factory_caching_enabled?, :factory_caching_enabled

    def cache_timeout=(seconds)
      raise ArgumentError, 'Cache timeout must be an Integer!' unless seconds.is_a?(Integer)
      @cache_timeout = seconds
    end

    def enable_factory_caching
      @factory_caching_enabled = true
    end

    def disable_factory_caching
      @factory_caching_enabled = false
    end

    def custom_cache_key=(block)
      raise ArgumentError, 'The custom cache key must be a Proc!' unless block.instance_of?(Proc)
      @custom_cache_key = block
    end
  end
end
