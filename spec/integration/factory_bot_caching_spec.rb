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

require 'spec_helper'
require 'timecop'
require 'active_record'
require 'factory_bot'

class FactoryCachingAssociationTest < ActiveRecord::Base
  self.table_name = 'factory_caching_association_test'
end

class FactoryCachingTest < ActiveRecord::Base
  self.table_name = 'factory_caching_test'

  belongs_to :factory_caching_association_test, class_name: 'FactoryCachingAssociationTest'
end

FactoryBot.define do
  factory :factory_caching_test, class: FactoryCachingTest do
    text 'Here is some text'
    status 'active'
    name 'Dough'

    trait :inactive do
      status 'inactive'
    end

    trait :new do
      status 'new'
    end

    trait :with_association do
      factory_caching_association_test
    end
  end

  factory :factory_caching_association_test, class: FactoryCachingAssociationTest do
    text 'Here is some text'
  end
end

describe 'Factory Caching' do
  before(:context) { @factories = {} }

  before(:context) do
    ActiveRecord::Migration.new.create_table(:factory_caching_test) do |t|
      t.string :name
      t.string :status
      t.string :text
      t.integer :factory_caching_association_test_id
    end

    ActiveRecord::Migration.new.create_table(:factory_caching_association_test) do |t|
      t.string :name
      t.string :status
      t.string :text
    end

    FactoryBotCaching.configure do |c|
      c.enable_factory_caching
      c.custom_cache_key = Proc.new { ::I18n.locale }
    end
  end

  after(:context) do
    ActiveRecord::Migration.new.drop_table(:factory_caching_test)
    ActiveRecord::Migration.new.drop_table(:factory_caching_association_test)
  end

  describe 'caching a factory', order: :defined do
    let(:five_minutes_past_hour)  { Time.new(2010,2,1,15,5,0) }
    let(:six_minutes_past_hour)   { Time.new(2010,2,1,15,6,0) }
    let(:seven_minutes_past_hour) { Time.new(2010,2,1,15,7,0) }
    let(:ten_minutes_past_hour)   { Time.new(2010,2,1,15,10,0) }

    before do
      allow(I18n).to receive(:locale).and_return(:'en-US')
    end

    it 'creates factory instances successfully' do
      Timecop.freeze(six_minutes_past_hour) do
        @factories[:created_six_minutes_past_hour] = FactoryBot.create(:factory_caching_test)
        expect(@factories[:created_six_minutes_past_hour]).to be_persisted
      end
    end

    it 'cached records are persisted across transactional tests' do
      previously_created_record_id = @factories[:created_six_minutes_past_hour].id
      expect(FactoryCachingTest.exists?(previously_created_record_id)).to be true
    end

    it 'returns factories that were cached by previous examples' do
      Timecop.freeze(seven_minutes_past_hour) do
        expect(FactoryBot.create(:factory_caching_test)).to eq @factories[:created_six_minutes_past_hour]
      end
    end

    it 'does not return factories that were cached under a different cache_key' do
      allow(I18n).to receive(:locale).and_return(:'en-Mars')
      Timecop.freeze(seven_minutes_past_hour) do
        mars_instance = FactoryBot.create(:factory_caching_test)
        @factories[:mars_created_seven_minutes_past_hour] = mars_instance
        expect(mars_instance).not_to eq @factories[:created_six_minutes_past_hour]
      end
    end

    it 'doesnt return factories created in the future' do
      # When Timecopped to before a previous test, it should not return the record that was created in the future
      Timecop.freeze(five_minutes_past_hour) do
        @factories[:created_five_minutes_past_hour] = FactoryBot.create(:factory_caching_test)
        expect(@factories[:created_five_minutes_past_hour]).not_to eq @factories[:created_six_minutes_past_hour]
      end
    end

    it 'returns factories that were cached under the same cache_key' do
      allow(I18n).to receive(:locale).and_return(:'en-Mars')
      Timecop.freeze(seven_minutes_past_hour) do
        previously_created_record_id = @factories[:mars_created_seven_minutes_past_hour].id
        expect(FactoryCachingTest.exists?(previously_created_record_id)).to be true
        expect(FactoryBot.create(:factory_caching_test)).to eq @factories[:mars_created_seven_minutes_past_hour]
      end
    end

    it 'returns factories created in the last 15 minutes in order by created_at' do
      # The previous tests created two cached records in reverse chronological order due to their Timecop times. We
      # expect to get those cached records back here in chronogical order by their created_at times, which is the
      # inverse of the order the tests actually ran in.
      Timecop.freeze(seven_minutes_past_hour) do
        factories = [
          FactoryBot.create(:factory_caching_test),
          FactoryBot.create(:factory_caching_test)
        ]
        expect(factories).to eq [@factories[:created_five_minutes_past_hour], @factories[:created_six_minutes_past_hour]]
      end
    end

    it 'returns multiple unique, cached instances of the same factory when called multiple times in same example' do
      Timecop.freeze(seven_minutes_past_hour) do
        factories = [
          FactoryBot.create(:factory_caching_test),
          FactoryBot.create(:factory_caching_test)
        ]
        expect(factories).to match_array [@factories[:created_five_minutes_past_hour], @factories[:created_six_minutes_past_hour]]
      end
    end

    it 'returns multiple new instances when called multiple times in same example' do
      Timecop.freeze(ten_minutes_past_hour) do
        expect(FactoryBot.create(:factory_caching_test)).to eq @factories[:created_five_minutes_past_hour]
        expect(FactoryBot.create(:factory_caching_test)).to eq @factories[:created_six_minutes_past_hour]
        @factories[:created_ten_minutes_past_hour_1] = FactoryBot.create(:factory_caching_test)
        @factories[:created_ten_minutes_past_hour_2] = FactoryBot.create(:factory_caching_test)

        expect(@factories[:created_ten_minutes_past_hour_1]).not_to eq @factories[:created_five_minutes_past_hour]
        expect(@factories[:created_ten_minutes_past_hour_1]).not_to eq @factories[:created_six_minutes_past_hour]

        expect(@factories[:created_ten_minutes_past_hour_2]).not_to eq @factories[:created_five_minutes_past_hour]
        expect(@factories[:created_ten_minutes_past_hour_2]).not_to eq @factories[:created_six_minutes_past_hour]
        expect(@factories[:created_ten_minutes_past_hour_2]).not_to eq @factories[:created_ten_minutes_past_hour_1]
      end
    end

    context 'traits' do
      it 'caches factories uniquely by trait' do
        @factories[:trait_1] = FactoryBot.create(:factory_caching_test)
        @factories[:trait_2] = FactoryBot.create(:factory_caching_test, :inactive)
        @factories[:trait_3] = FactoryBot.create(:factory_caching_test, :new)
        expect(@factories[:trait_1]).not_to eq @factories[:trait_2]
        expect(@factories[:trait_1]).not_to eq @factories[:trait_3]
        expect(@factories[:trait_2]).not_to eq @factories[:trait_3]
      end

      it 'retrieves cached factories uniquely by trait' do
        expect(FactoryBot.create(:factory_caching_test)).to eq @factories[:trait_1]
        expect(FactoryBot.create(:factory_caching_test, :inactive)).to eq @factories[:trait_2]
        expect(FactoryBot.create(:factory_caching_test, :new)).to eq @factories[:trait_3]
      end
    end

    context 'overrides' do
      it 'creates records with overrides' do
        @factories[:cacheable_overrides]   = FactoryBot.create(:factory_caching_test, status: 'limbo')
        @factories[:uncacheable_overrides] = FactoryBot.create(:factory_caching_test, factory_caching_association_test: FactoryBot.create(:factory_caching_association_test))
      end

      it 'caches factory calls where table values are overridden' do
        cachable_record = FactoryBot.create(:factory_caching_test, status: 'limbo')
        expect(cachable_record).to eq @factories[:cacheable_overrides]
      end

      it 'does not cache factory calls which have overrides of their associations' do
        uncachable_record = FactoryBot.create(:factory_caching_test, factory_caching_association_test: FactoryBot.create(:factory_caching_association_test))
        expect(uncachable_record).not_to eq @factories[:uncacheable_overrides]
      end
    end
  end

  describe 'with caching disabled', :no_factory_caching, order: :defined do
    it 'creates factory instances successfully' do
      @factories[:created_without_caching] = FactoryBot.create(:factory_caching_test)
      expect(@factories[:created_without_caching]).to be_persisted
    end

    it 'does not return cached factories' do
      expect(FactoryBot.create(:factory_caching_test)).not_to eq @factories[:created_without_caching]
    end
  end
end
