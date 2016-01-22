# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'portal/version'

Gem::Specification.new do |spec|
  spec.name          = "portal"
  spec.version       = Portal::VERSION
  spec.authors       = ["Tyler Flint"]
  spec.email         = ["tyler@nanobox.io"]

  spec.summary       = %q{Ruby client for interacting with the portal service}
  spec.homepage      = "https://github.com/nanopack/portal-client-ruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "faraday", "~> 0.9"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "webmock", "~> 1.22"
  spec.add_development_dependency "sinatra", "~> 1.4"
end
