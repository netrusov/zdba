# frozen_string_literal: true

require_relative 'lib/zdba/version'

::Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 3.4'

  spec.name = 'zdba'
  spec.version = ::ZDBA::VERSION
  spec.summary = 'Zabbix Database Agent'
  spec.license = 'MIT'

  spec.author = 'Alexander Netrusov'

  spec.metadata = {
    'bug_tracker_uri' => 'https://github.com/netrusov/zdba/issues',
    'changelog_uri' => "https://github.com/netrusov/zdba/releases/tag/v#{spec.version}",
    'source_code_uri' => "https://github.com/netrusov/zdba/tree/v#{spec.version}",
    'rubygems_mfa_required' => 'true',
  }

  spec.files = ::Dir['lib/**/*', 'schemas/**/*', 'templates/**/*', 'LICENSE']
  spec.bindir = 'bin'
  spec.executables = ['zdba']
  spec.require_paths = ['lib']

  spec.add_dependency('json-schema', '>= 5.0.0')
  spec.add_dependency('logger', '>= 1.0.0')
  spec.add_dependency('sequel', '>= 5.0.0')
  spec.add_dependency('thor', '>= 1.0.0')
end
