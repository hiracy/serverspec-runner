# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'serverspec-runner/version'

Gem::Specification.new do |spec|
  spec.name = "serverspec-runner"
  spec.version = ServerspecRunner::VERSION
  spec.authors = ["hiracy"]
  spec.email = ["leizhen@mbr.nifty.com"]
  spec.description = %q{simple execution framework for serverspec}
  spec.summary = %q{simple execution framework for serverspec}
  spec.homepage = "https://github.com/hiracy/serverspec-runner"
  spec.license = "MIT"
  
  spec.files = `git ls-files`.split($/)
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]
  
  spec.add_runtime_dependency     "serverspec"
  spec.add_runtime_dependency     "net-ssh"
  spec.add_runtime_dependency     'psych'
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec-core"
  spec.add_development_dependency "bundler", "~> 1.3"
end
