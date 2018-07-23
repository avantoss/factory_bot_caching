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

require 'factory_bot_caching/factory_record_cache'
require 'timecop'

describe FactoryBotCaching::FactoryRecordCache do
  subject { described_class.new(build_class: build_class) }

  let(:build_class) do
    Class.new(ActiveRecord::Base) do
      self.table_name = 'factory_record_cache_test'
    end
  end

  # Even though we are stubbing records in our test, we need the table to actually exist. Otherwise ActiveRecord
  # complains when trying to create instances of the build class.
  before(:context) do
    ActiveRecord::Migration.new.create_table(:factory_record_cache_test) do |t|
      t.string :text
    end
  end

  after(:context) do
    ActiveRecord::Migration.new.drop_table(:factory_record_cache_test)
  end

  # These stubbed records are returned in order when creating new records
  let(:created_record_1) { build_class.new(id: 1) }
  let(:created_record_2) { build_class.new(id: 2) }
  let(:created_record_3) { build_class.new(id: 3) }
  let(:created_record_4) { build_class.new(id: 4) }
  # These records are returned by the cache retrieval process
  let(:cached_record_1)  { build_class.new(id: 1) }
  let(:cached_record_2)  { build_class.new(id: 2) }


  before do
    allow(FactoryBotCaching).to receive(:without_caching).and_return(created_record_1, created_record_2, created_record_3, created_record_4)
    allow(build_class).to receive(:find_by).with('id' => 1).and_return(cached_record_1)
    allow(build_class).to receive(:find_by).with('id' => 2).and_return(cached_record_2)
  end

  describe '#reset_counters' do
    it 'resets the enumerator cache to allow pulling records from the cache for the next test' do
      record_1 = subject.fetch(overrides: [], traits: []) { true }
      record_2 = subject.fetch(overrides: [], traits: []) { true }
      expect(record_1).to be created_record_1
      expect(record_2).to be created_record_2

      # After resetting 'counters', the cache will return records from the top of the cache
      subject.reset_counters

      record_1 = subject.fetch(overrides: [], traits: []) { true }
      record_2 = subject.fetch(overrides: [], traits: []) { true }
      expect(record_1).to be cached_record_1
      expect(record_2).to be cached_record_2
    end
  end

  describe '#fetch' do
    it 'creates a new record if none already exists in the factory cache' do
      record_1 = subject.fetch(overrides: [], traits: []) { true }
      expect(record_1).to be created_record_1
    end

    it 'caches new records and returns them in the future after resetting the enumerator cache' do
      record_1 = subject.fetch(overrides: [], traits: []) { true }
      expect(record_1).to be created_record_1

      subject.reset_counters

      record_1 = subject.fetch(overrides: [], traits: []) { true }
      expect(record_1).to be cached_record_1
    end

    it 'returns multiple existing records if they exist in the factory cache, in chronological order by creation time' do
      Timecop.freeze(2016, 1, 1, 12, 0, 5) do
        subject.fetch(overrides: [], traits: []) { true }
      end
      Timecop.freeze(2016, 1, 1, 12, 0, 0) do
        subject.fetch(overrides: [], traits: []) { true }
      end

      subject.reset_counters

      Timecop.freeze(2016, 1, 1, 12, 1, 0) do
        refetch_1 = subject.fetch(overrides: [], traits: []) { true }
        refetch_2 = subject.fetch(overrides: [], traits: []) { true }
        expect(refetch_1).to be cached_record_2
        expect(refetch_2).to be cached_record_1
      end
    end
    
    it 'returns different cached records when different overrides are specified' do
      subject.fetch(overrides: [first_name: 'foo'], traits: []) { true }
      subject.fetch(overrides: [last_name:  'bar'], traits: []) { true }

      subject.reset_counters

      fetched_1 = subject.fetch(overrides: [last_name:  'bar'], traits: []) { true }
      fetched_2 = subject.fetch(overrides: [first_name: 'foo'], traits: []) { true }
      # Because fetch order of the traits are reversed in the refetch, we should get reversed results back:
      expect(fetched_1).to be cached_record_2
      expect(fetched_2).to be cached_record_1
    end

    it 'returns different cached records when different override values are specified' do
      subject.fetch(overrides: [first_name: 'foo'], traits: []) { true }
      subject.fetch(overrides: [first_name: 'bar'], traits: []) { true }

      subject.reset_counters

      fetched_1 = subject.fetch(overrides: [first_name: 'bar'], traits: []) { true }
      fetched_2 = subject.fetch(overrides: [first_name: 'foo'], traits: []) { true }
      # Because fetch order of the traits are reversed in the refetch, we should get reversed results back:
      expect(fetched_1).to be cached_record_2
      expect(fetched_2).to be cached_record_1
    end

    it 'returns different cached records when different traits are specified' do
      subject.fetch(overrides: [], traits: [:foo]) { true }
      subject.fetch(overrides: [], traits: [:bar]) { true }

      subject.reset_counters

      fetched_1 = subject.fetch(overrides: [], traits: [:bar]) { true }
      fetched_2 = subject.fetch(overrides: [], traits: [:foo]) { true }
      # Because fetch order of the traits are reversed in the refetch, we should get reversed results back:
      expect(fetched_1).to be cached_record_2
      expect(fetched_2).to be cached_record_1
    end

    it 'does not return records created more than the configured cache_timeout seconds ago' do
      allow(FactoryBotCaching.configuration).to receive(:cache_timeout).and_return(900)

      Timecop.freeze(2016, 1, 1, 12, 0, 0) do
        subject.fetch(overrides: [], traits: []) { true }
      end

      Timecop.freeze(2016, 1, 1, 12, 0, 2) do
        subject.fetch(overrides: [], traits: []) { true }
      end

      subject.reset_counters

      Timecop.freeze(2016, 1, 1, 12, 15, 1) do
        fetched_1 = subject.fetch(overrides: [], traits: []) { true }
        fetched_2 = subject.fetch(overrides: [], traits: []) { true }
        expect(fetched_1).to be cached_record_2
        expect(fetched_2).to be created_record_3
      end
    end

    it 'does not return records created in the future' do
      Timecop.freeze(2016, 1, 1, 12, 0, 1) do
        subject.fetch(overrides: [], traits: []) { true }
      end

      subject.reset_counters

      Timecop.freeze(2016, 1, 1, 12, 0, 0) do
        fetched_1 = subject.fetch(overrides: [], traits: []) { true }
        expect(fetched_1).to be created_record_2
      end
    end

    it 'returns new records after having returned all matching cached records' do
      subject.fetch(overrides: [], traits: []) { true }
      subject.fetch(overrides: [], traits: []) { true }

      subject.reset_counters

      fetched_1 = subject.fetch(overrides: [], traits: []) { true }
      fetched_2 = subject.fetch(overrides: [], traits: []) { true }
      fetched_3 = subject.fetch(overrides: [], traits: []) { true }
      expect(fetched_1).to be cached_record_1
      expect(fetched_2).to be cached_record_2
      expect(fetched_3).to be created_record_3
    end

    it 'does not return records whose record cannot be retrieved from the database' do
      subject.fetch(overrides: [], traits: []) { true }
      allow(build_class).to receive(:find_by).with('id' => 1).and_return(nil)

      subject.reset_counters

      fetched_1 = subject.fetch(overrides: [], traits: []) { true }
      expect(fetched_1).to be created_record_2
    end
  end
end
