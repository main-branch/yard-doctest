# frozen_string_literal: true

version = File.read(File.expand_path('lib/yard/doctest/version.rb', __dir__)).match(/VERSION = ['"](.*?)['"]/)[1]

Gem::Specification.new do |spec|
  spec.name         = 'yard-doctest'
  spec.version      = version
  spec.author       = 'Alex Rodionov'
  spec.email        = 'p0deje@gmail.com'
  spec.summary      = 'Doctests from YARD examples'
  spec.description  = 'Execute YARD examples as tests'
  spec.homepage     = 'https://github.com/p0deje/yard-doctest'
  spec.license      = 'MIT'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end

  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'minitest', '~> 6.0'
  spec.add_runtime_dependency 'yard', '~> 0.9'

  spec.add_development_dependency 'aruba', '~> 2.3'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'relish', '~> 0.7'
  spec.add_development_dependency 'rspec', '~> 3.13'
  spec.add_development_dependency 'rubocop', '~> 1.84'
  spec.add_development_dependency 'ruby-lsp', '~> 0.26'
  spec.add_development_dependency 'simplecov', '~> 0.22'
  spec.add_development_dependency 'yardstick', '~> 0.9'
end
