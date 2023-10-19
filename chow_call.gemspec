# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chow/call/version'

Gem::Specification.new do |spec|
  spec.name          = "chow-call"
  spec.version       = Chow::Call::VERSION
  spec.authors       = ["WeWork Engineering", "Chowly Engineering"]
  spec.email         = ["engineering@wework.com", "engineering@chowlyinc.com"]

  spec.summary       = "Making healthy, happy HTTP calls"
  spec.description   = "Handles conventions of making calls to other services, with required metadata for tracking calls between services, deprecations of endpoints, trace IDs, throttling, etc."
  spec.homepage      = "https://github.com/chowly/chow-call"
  spec.licenses      = ['MIT']

  spec.files                = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(spec)/})
  end
  spec.bindir               = "bin"
  spec.require_paths        = ["lib"]

  spec.add_dependency "typhoeus", "~> 1.4"
  spec.add_dependency "faraday", "~> 1.5.1"
  spec.add_dependency "faraday_middleware"

  spec.add_development_dependency "appraisal", "~> 2.0"
  spec.add_development_dependency "coveralls_reborn", '~> 0.13'
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rails", '~> 6.1.4.4'
  spec.add_development_dependency "rspec", "~> 3.5"
  spec.add_development_dependency "simplecov", '~> 0.15'
  spec.add_development_dependency "hashie", "~> 3.5"
  spec.add_development_dependency "vcr", '~> 4.0'
end
