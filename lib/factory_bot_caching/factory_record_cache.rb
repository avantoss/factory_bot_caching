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

require_relative 'immutable_iterator'
require_relative 'module_methods'

module FactoryBotCaching
  class FactoryRecordCache
    CacheEntry = Struct.new(:created_at, :identifier)

    def initialize(build_class:)
      @build_class = build_class
      @cache = Hash.new do |factory_hash, key|
        factory_hash[key] = []
      end
      reset_counters
    end

    def fetch(overrides:, traits:, &block)
      key = {overrides: overrides, traits: traits}
      now        = Time.now
      enumerator = enumerator_for(key, at: now)

      enumerator.until_end do |entry|
        # Entries are sorted by created at, so we can break as soon as we see an entry created_at after now
        break if entry.created_at > now
        record = build_class.find_by(build_class.primary_key => entry.identifier)
        return record unless record.nil?
      end

      cache_new_record(key, &block)
    end

    def reset_counters
      @enumerator_cache = Hash.new do |enumerator_hash, key|
        enumerator_hash[key] = ImmutableIterator.new(cache[key])
      end
    end

    private

    attr_reader :build_class, :cache, :enumerator_cache

    def enumerator_for(key, at:)
      enumerator    = enumerator_cache[key]
      boundary_time = lookback_start_time(time: at)
      enumerator.fast_forward { |entry| entry.created_at > boundary_time }
      enumerator
    end

    def lookback_start_time(time: Time.now)
      time - FactoryBotCaching.configuration.cache_timeout
    end

    def cache_new_record(cache_key, &block)
      new_record = process_block(&block)
      primary_key = new_record.class.primary_key

      entry = CacheEntry.new(Time.now, new_record[primary_key])
      cached_records = cache[cache_key]

      insert_at_index = cached_records.find_index { |record| record.created_at > entry.created_at }
      if insert_at_index.nil?
        cached_records << entry
      else
        cached_records.insert(insert_at_index, entry)
      end

      new_record
    end

    def process_block(&block)
      record = nil

      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do |conn|
          conn.execute("SET statement_timeout = '20s'")
          record = FactoryBotCaching.without_caching(&block)
        end
      end.join
      record
    rescue => e
      # Append the backtrace of the current thread to the backtrace of the joined thread
      e.set_backtrace(e.backtrace + caller)
      raise e
    end
  end
end
