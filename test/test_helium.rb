require "test/unit"
require "helium"
require "fileutils"

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
