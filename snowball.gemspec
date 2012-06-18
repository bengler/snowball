# -*- encoding: utf-8 -*-
require File.expand_path('../lib/snowball/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Bjørge Næss"]
  gem.email         = ["bjoerge@bengler.no"]
  gem.description   = %q{A better way of managing and serving your front-end dependencies}
  gem.summary       = %q{It currently uses browserify to roll a ball of your application npm dependencies}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "snowball"
  gem.require_paths = ["lib"]
  gem.version       = Snowball::VERSION

  gem.extensions = "Rakefile"
  
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "rack-test"
  gem.add_development_dependency "sinatra"
end