# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pipedriver/version'

Gem::Specification.new do |gem|
  gem.name          = "pipedriver"
  gem.version       = Pipedriver::VERSION
  gem.authors       = ["Lachy Groom"]
  gem.email         = ["lachygroom@gmail.com"]
  gem.description   = %q{Pipedrive API Wrapper}
  gem.summary       = %q{A gem to wrap the pipedrive API}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  
  gem.add_dependency('rest-client', '~> 1.4')
  gem.add_dependency('multi_json', '~> 1.1')  
  gem.add_dependency('active_support')
  gem.add_development_dependency 'minitest'
  gem.add_development_dependency 'nokogiri'
  gem.add_development_dependency 'json'
end
