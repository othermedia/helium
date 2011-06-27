require "rubygems"
require "bundler/setup"

require "test/unit"
require "fileutils"
require File.expand_path("../../lib/helium", __FILE__)

ROOT = File.dirname(__FILE__)

class TestHelium < Test::Unit::TestCase
  def setup
    FileUtils.rm_rf(ROOT + '/output')
  end
  
  def test_build
    deploy = Helium::Deployer.new(ROOT, 'output', :domain => 'helium.example.com')
    deploy.add_observer(self)
    deploy.run!
  end
  
  def update(type, message)
    puts "**** [LOG] #{ message }"
  end
end
