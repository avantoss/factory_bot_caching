# FactoryBotCaching

[![CircleCI](https://circleci.com/gh/avantoss/factory_bot_caching.svg?style=svg)](https://circleci.com/gh/avantoss/factory_bot_caching)

FactoryBotCaching is a gem which implements a caching layer for FactoryBot with Rails/ActiveRecord.

Factory Caching enables you to leverage the flexibility of factories with some of the performance benefits
of fixtures.

## FactoryGirl Support

* `FactoryBotCaching` `~> 2.0.0` currently only offers built-in support for the `FactoryBot` gem/namespace.
* Support for the older `FactoryGirl` namespace is available in version 1.0.0

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'factory_bot_caching', :group => :test
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install factory_bot_caching

## Usage

### Configuration

FactoryBotCaching is disabled by default.  To enable it, add a configuration block like the following to your test
setup file(s) to enable caching and configure any other options as desired:

```ruby
# rails_helper.rb
require 'factory_bot_caching'

FactoryBotCaching.configure do |config|
  config.enable_factory_caching # Defaults to factory caching disabled.
  config.cache_timeout = 300 # Optional. Defaults to 900 seconds
  config.custom_cache_key = Proc.new { ::I18n.locale } # Optional. Defaults to nil / no custom caching layer.
end
```

#### Configuration Options:

##### enable_factory_caching

Turns factory caching on.

##### disable_factory_caching

Disables factory caching.

##### cache_timeout

The amount of time in seconds after creation that a cached factory record is considered valid to be returned from
the cache. Defaults to 900 seconds (15 minutes).

##### custom_cache_key

The `custom_cache_key` is a Proc that can be executed to generate a value or list/hash of values to use as a custom
 cache key for cached records.  By default, no custom caching layer is used.

For example, if you have factories which behave differently across locales, you may want to use a `custom_cache_key` which
adds a caching layer on top of the value returned by `::I18n.locale`.

```ruby
Proc.new { ::I18n.locale }
```

This prevents records created in the 'en-GB' locale from being returned in tests run in 'en-US' locale.

NOTE: It is not necessary to add a custom cache key for time or date.  Changes in date and time by libraries such as
`TimeCop` are already handled automatically by the built in caching layers and the `cache_timeout` value.

### Setup/Teardown Hooks

In addition to configuring/enabling Factory Caching, it is necessary to configure hooks in your test suite to initialize
at the start of testing and reset cache counters after each test.

### RSpec

#### Disable Trasactional Fixtures

For factory caching to work correctly, you must ensure that the `rspec-rails` `use_transactional_fixtures` setting is disabled:

```ruby
RSpec.configure do |config|
  config.use_transactional_fixtures = false
end
```

To run tests inside of transactions, we recommend using [DatabaseCleaner](https://rubygems.org/gems/database_cleaner) instead.

#### Enable Factory Caching

`FactoryBotCaching` provides a setup script for RSpec. This adds the necessary test hooks to an RSpec test suite to set
up and tear down factory caching in your test suite.

In your test setup after requiring FactoryBot:

```ruby
# rails_helper.rb
require 'factory_bot_caching/rspec'
```

It also adds a metadata filter to exclude specific tests from caching if they always require new records to be created:

```ruby
RSpec.describe "factory caching metadata" do
  it "runs with caching disabled", :no_factory_caching do
    expect(FactoryBotCaching.enabled?).to be false
  end

  it "runs with caching disabled" do
    expect(FactoryBotCaching.enabled?).to be true
  end
end
```

### Other Test Frameworks

To use Factory Bot Caching in other test frameworks, see `lib/factory_bot_caching/rspec.rb` for the necessary callbacks
that must be run to use caching.

Specifically, you must call `FactoryBotCaching.initialize` before running any tests, and
`FactoryBotCaching::CacheManager.instance.reset_cache_counter` after each test.

Pull requests to add support for other test frameworks are welcome!

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/avantoss/factory_bot_caching. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## Roadmap

### v2.0
* Support FactoryBot
