require 'rubygems'
require 'sinatra'
require 'yaml'

ROOT_DIR = File.expand_path( File.dirname(__FILE__) )
require File.join(ROOT_DIR, '..', 'lib', 'tom_deployer')

LIB_DIR  = 'lib'
CONFIG   = File.join(ROOT_DIR, 'deploy.yml')

def project_config
  File.file?(CONFIG) ? YAML.load(File.read(CONFIG)) : {}
end

## GET /
##
get '/' do
  @projects = project_config
  erb :index
end

## POST /deploy
##
post '/deploy' do
  deployer = TomDeployer.new(ROOT_DIR, LIB_DIR)
  logger   = Logger.new
  deployer.add_observer(logger)
  
  params[:projects].each do |name, value|
    next unless value == '1'
    deployer.deploy!(name, false)
  end
  deployer.run_builds!
  
  @projects = project_config
  @log = logger.messages
  erb :index
end

## GET /config
##
get '/config' do
  @projects = project_config
  @yaml = File.file?(CONFIG) ? File.read(CONFIG) : ''
  erb :config
end

## POST /config
##
post '/config' do
  @yaml = params[:yaml]
  begin
    YAML.load(@yaml)
    File.open(CONFIG, 'w') { |f| f.write(@yaml) }
  rescue
    @error = 'File not saved: invalid YAML'
  end
  @projects = project_config
  erb :config
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

