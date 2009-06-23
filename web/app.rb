require 'rubygems'
require 'sinatra'
require 'yaml'

ROOT_DIR = File.expand_path( File.dirname(__FILE__) )
require File.join(ROOT_DIR, '..', 'lib', 'tom_deployer')

LIB_DIR  = 'lib'
CONFIG   = File.join(ROOT_DIR, 'deploy.yml')

def project_config
  YAML.load(File.read(CONFIG))
end

get '/' do
  @projects = projects
  erb :index
end

post '/deploy' do
  deployer = TomDeployer.new(ROOT_DIR, LIB_DIR)
  logger   = Logger.new
  deployer.add_observer(logger)
  
  params[:projects].each do |name, value|
    next unless value == '1'
    deployer.run!(name)
  end
  
  @projects = project_config
  @log = logger.messages
  erb :index
end

class Logger
  attr_reader :messages
  def initialize
    @messages = []
  end
  
  def update(type, msg)
    @messages << msg.gsub(File.join(ROOT_DIR, LIB_DIR), '')
  end
end

