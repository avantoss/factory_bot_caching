require_relative 'lib/factory_bot_caching/version'

Gem::Specification.new do |spec|
  spec.name          = "factory_bot_caching"
  spec.version       = FactoryBotCaching::VERSION
  spec.authors       = ["Tim Mertens"]
  spec.email         = ["tim.mertens@filmchicago.org"]
  spec.summary       = %q{factory_bot_caching provides a caching mechanism for records created by Factory Bot/Girl to significantly reduce test suite runtimes.}
  spec.license       = "MIT"

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
