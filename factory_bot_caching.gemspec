require_relative 'lib/factory_bot_caching/version'

Gem::Specification.new do |spec|
  spec.name          = "factory_bot_caching"
  spec.version       = FactoryBotCaching::VERSION
  spec.authors       = ["Tim Mertens"]
  spec.email         = ["tim.mertens@filmchicago.org"]
  spec.summary       = "A caching mechanism for test suites using Factory Bot/Factory Girl with ActiveRecord."
  spec.description   = %q{The factory_bot_caching gem provides a caching mechanism for Factory Bot/Factory Girl to significantly reduce test suite runtimes in factory heavy test suites.}
  spec.license       = "MIT"
  spec.homepage      = "https://github.com/avantoss/factory_bot_caching"


  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "factory_girl", "~> 4.4"

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.6"
  spec.add_development_dependency "activerecord", "~> 4.0"
  spec.add_development_dependency "activesupport", "~> 4.0"
  spec.add_development_dependency "database_cleaner", "~> 1.0"
  spec.add_development_dependency "pg", "~> 0.18"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rspec_junit_formatter"
end
