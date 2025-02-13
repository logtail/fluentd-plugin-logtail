# -*- encoding: utf-8 -*-
require 'date'

Gem::Specification.new do |s|
  s.name        = 'fluent-plugin-logtail'
  s.version     = '0.2.1'
  s.date        = Date.today.to_s
  s.summary     = 'Logtail.com plugin for Fluentd'
  s.description = 'Streams Fluentd logs to the Logtail.com logging service.'
  s.authors     = ['Logtail.com']
  s.email       = 'hello@logtail.com'
  s.homepage    = 'https://github.com/logtail/fluent-plugin-logtail'
  s.license     = 'ISC'

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = Gem::Requirement.new(">= 2.4.0".freeze)

  s.add_runtime_dependency('fluentd', '> 1', '< 2')

  s.add_development_dependency('rspec', '~> 3.4')
  s.add_development_dependency('test-unit', '~> 3.3.9')
  s.add_development_dependency('webmock', '~> 2.3')
end
