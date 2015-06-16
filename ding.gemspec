# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ding/version'

Gem::Specification.new do |spec|
  spec.name          = 'ding'
  spec.version       = Ding::VERSION
  spec.authors       = ['Warren Bain']
  spec.email         = ['warren@thoughtcroft.com']

  spec.summary       = %q{Push specific feature branch code to a testing branch}
  spec.description   = %q{Private ARIS gem for managing QA deployment of feature branches for testing}

  spec.files         = `git ls-files -z`.split('\x0').reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'http://mygemserver.com'
  end

  spec.add_development_dependency 'bundler', '~> 1.8'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_runtime_dependency     'thor', '~> 0.19'
  spec.add_runtime_dependency     'git-up'
end
