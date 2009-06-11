require "test/unit"
require "tom_deployer"
require "fileutils"

ROOT = File.dirname(__FILE__)

class TestTomDeployer < Test::Unit::TestCase
  def setup
    FileUtils.rm_rf(ROOT + '/output')
  end
  
  def test_build
    deploy = TomDeployer.new(ROOT, 'output')
    deploy.add_observer(self)
    deploy.run!
  end
  
  def update(type, message)
    puts "**** [LOG] #{ message }"
  end
end
