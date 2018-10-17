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

require_relative 'customized_cache'

module FactoryBotCaching
  class FactoryCache
    def initialize(factory_name:)
      @factory_name       = factory_name
      @build_class        = FactoryBot.factory_by_name(factory_name).build_class
      @cache              = new_cache(@build_class)
      @cachable_overrides = []
      collect_uncachable_traits
    end

    attr_reader :factory_name

    def fetch(overrides:, traits:, &block)
      key = { overrides: overrides, traits: traits}
      if should_cache?(key)
        cache.fetch(key, &block)
      else
        block.call
      end
    end

    def reset
      @cache = new_cache(build_class)
    end

    def reset_counter
      cache.reset_counters
    end

    private

    attr_reader :cache, :build_class

    def new_cache(build_class)
      if FactoryBotCaching.configuration.custom_cache_key.nil?
        FactoryRecordCache.new(build_class: build_class)
      else
        CustomizedCache.new(
          build_class: build_class,
          cache_key_generator: FactoryBotCaching.configuration.custom_cache_key)
      end
    end

    # Collect a list of traits that are considered 'uncachable' if passed in the overrides list.
    # We collect two lists - belongs_to associations, which have a high probability to be overridden in
    # a factory call and should be compared against first, followed by uncommon_associations
    def collect_uncachable_traits
      return unless build_class < ActiveRecord::Base

      @common_associations = []
      @uncommon_associations  = []

      reflections = build_class.reflect_on_all_associations
      reflections.each do |reflection|
        if reflection.macro == :belongs_to
          @common_associations << reflection.name.to_sym
          # In rails land, some foreign keys are symbols, some strings; coerce them here:
          @common_associations << reflection.foreign_key.to_sym
        else
          @uncommon_associations << reflection.name.to_sym
        end
      end
    end

    attr_reader :common_associations, :uncommon_associations, :cachable_overrides

    # Determine whether or not an overridden value in a factory call is cacheable.
    # We use some caching and perform comparisons in order of probability which nets a 70x improvement in
    # performance over previous versions of this validation.
    #
    # For example:
    #   FactoryBot.create(:customer, name: 'John Doe', email: 'john.doe@example.test')
    #   FactoryBot.create(:customer, name: 'John Doe', address_id: 123)
    #
    # In the above examples, `address_id` is a passed in association and should not be cached.
    #
    # @param override_sym [Symbol]
    # @return [Boolean] true if the overridden value is cacheable, false otherwise
    def cacheable_override?(override_sym)
      # Search in order of probability to reduce lookup times:
      return true  if cachable_overrides.include?(override_sym)
      return false if common_associations.include?(override_sym)
      return false if uncommon_associations.include?(override_sym)
      cachable_overrides << override_sym
      true
    end

    # Skip caching for factories that are called with passed in associations, as it mutates the association and persisted record
    def should_cache?(key)
      return false unless build_class < ActiveRecord::Base

      key[:overrides].all? do |key, v|
        cacheable_override?(key.to_sym)
      end
    end
  end
end
