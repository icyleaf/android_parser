# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'android_parser'
  spec.version       = '2.5.1'
  spec.authors       = ['SecureBrain', 'icyleaf']
  spec.email         = ['info@securebrain.co.jp', 'icyleaf.cn@gmail.com']
  spec.platform      = Gem::Platform::RUBY
  spec.summary       = 'Static analysis tool for android apk since 2021'
  spec.description   = 'Static analysis tool for android apk since 2021'
  spec.homepage      = 'https://github.com/icyleaf/android_parser'
  spec.license       = 'MIT'
  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.5'

  spec.add_dependency 'rubyzip', '>= 1.0', '< 3.0'

  if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('3.0.0') then
    spec.add_dependency 'rexml', '> 3.0'
  end

  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rspec-its', '>= 1.2.0'
  spec.add_development_dependency 'rspec-collection_matchers', '>= 1.1.0'
  spec.add_development_dependency 'rspec-mocks', '>= 3.6.0'
  spec.add_development_dependency 'bundler', '>= 1.12'
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'awesome_print'
end
