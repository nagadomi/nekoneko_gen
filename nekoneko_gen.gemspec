# -*- coding: utf-8 -*-
require File.expand_path('../lib/nekoneko_gen/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["nagadomi"]
  gem.email         = ["nagadomi@nurs.or.jp"]
  gem.description   = %q{Japanese Text Classifier Generator}
  gem.summary       = %q{Japanese Text Classifier Generator}
  gem.homepage      = "http://github.com/nagadomi/nekoneko_gen"
  
  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "nekoneko_gen"
  gem.require_paths = ["lib"]
  gem.version       = NekonekoGen::VERSION
  
  gem.add_dependency 'bimyou_segmenter'
  gem.add_dependency 'json'
  gem.add_development_dependency 'test-unit'
end
