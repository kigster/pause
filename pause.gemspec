# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pause/version'

Gem::Specification.new do |gem|
  gem.name          = 'pause'
  gem.version       = Pause::VERSION
  gem.authors       = ['Konstantin Gredeskoul', 'Atasay Gokkaya', 'Paul Henry', 'Eric Saxby']
  gem.email         = %w(kigster@gmail.com atasay@wanelo.com paul@wanelo.com sax@ericsaxby.com)
  gem.summary       = %q(Fast, scalable, and flexible real time rate limiting library for distributed Ruby environments backed by Redis.)
  gem.description   = %q(This gem provides highly flexible and easy to use interface to define rate limit checks, register events as they come, and verify if the rate limit is reached. Multiple checks for the same metric are easily supported. This gem is used at very high scale on several popular web sites.)
  gem.homepage      = 'https://github.com/kigster/pause'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_dependency 'colored2'
  gem.add_dependency 'redis'

  # optional
  # gem.add_dependency 'hiredis'
end
