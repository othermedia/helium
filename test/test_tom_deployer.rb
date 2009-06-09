require "test/unit"
require "tom_deployer"
require "fileutils"

ROOT = File.dirname(__FILE__)

class TestTomDeployer < Test::Unit::TestCase
  def setup
    FileUtils.rm_rf(ROOT + '/output')
  end
  
  def test_build
    TomDeployer.new(ROOT).run!('output')
  end
end
