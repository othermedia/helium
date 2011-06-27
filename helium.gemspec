Gem::Specification.new do |s|
  s.name        = "helium"
  s.version     = "0.1.3"
  s.platform    = Gem::Platform::RUBY
  s.license     = "GPL"
  s.author      = "James Coglan"
  s.email       = "james.coglan@othermedia.com"
  s.homepage    = "https://github.com/othermedia/helium"
  s.summary     = "Git-backed JavaScript deployment"
  s.description = "A web application for running a Git-backed JavaScript
                   package distribution system.".sub(/\s+/, " ")
  
  s.add_dependency('grit', '>= 0')
  s.add_dependency('jake', '>= 1.0.1')
  s.add_dependency('packr', '>= 3.1')
  s.add_dependency('oyster', '>= 0.9.3')
  s.add_dependency('sinatra', '>= 0.9.4')
  s.add_dependency('rack', '>= 1.0')
  
  s.executables = ['he']
  
  s.files       = %w(History.txt LICENCE README.rdoc) +
                  Dir.glob("{bin,lib,templates}/**/*")
                  
  s.test_file   = "test/test_helium.rb"
end
