#!/usr/bin/env gem build
# encoding: utf-8

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)

require 'helium'

Gem::Specification.new do |s|
  s.name        = "helium"
  s.version     = Helium::VERSION
  s.platform    = Gem::Platform::RUBY
  s.license     = "GPL"
  s.author      = "James Coglan"
  s.email       = "james.coglan@othermedia.com"
  s.homepage    = "https://github.com/othermedia/helium"
  s.summary     = "Git-backed JavaScript deployment"
  s.description = "A web application for running a Git-backed JavaScript
                   package distribution system.".sub(/\s+/, " ")
  
  s.required_rubygems_version = ">= 1.3"
  
  s.add_dependency('grit', '>= 0')
  s.add_dependency('jake', '>= 1.0.1')
  s.add_dependency('packr', '>= 3.1')
  s.add_dependency('oyster', '>= 0.9.3')
  s.add_dependency('sinatra', '>= 0.9.4')
  s.add_dependency('rack', '>= 1.0')
  
  s.files       = Dir.glob("lib/**/*.rb") +
                  Dir.glob("lib/helium/public/*.{css,js}") +
                  Dir.glob("lib/helium/views/*.erb") +
                  Dir.glob("templates/**/*") +
                  Dir.glob("test/*.*") +
                  %w(History.txt LICENCE README.rdoc)
  s.test_file   = "test/test_helium.rb"
end
