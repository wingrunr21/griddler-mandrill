# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'griddler/mandrill/version'

Gem::Specification.new do |spec|
  spec.name          = 'griddler-mandrill'
  spec.version       = Griddler::Mandrill::VERSION
  spec.authors       = ['Stafford Brunk']
  spec.email         = ['stafford.brunk@gmail.com']
  spec.summary       = %q{Mandrill adapter for Griddler}
  spec.description   = %q{Adapter to allow the use of Mandrill's Inbound Email Processing with Griddler}
  spec.homepage      = 'https://github.com/wingrunr21/griddler-mandrill'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'griddler'

  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'activesupport'
end
