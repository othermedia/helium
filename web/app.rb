require 'rubygems'
require 'sinatra'
require 'yaml'

ROOT_DIR = File.expand_path( File.dirname(__FILE__) )
require File.join(ROOT_DIR, '..', 'lib', 'helium')

LIB_DIR  = 'lib'
CONFIG   = File.join(ROOT_DIR, 'deploy.yml')
CUSTOM   = File.join(ROOT_DIR, 'custom.js')

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
  deployer = Helium::Deployer.new(ROOT_DIR, LIB_DIR)
  logger   = Logger.new
  deployer.add_observer(logger)
  
  params[:projects].each do |name, value|
    next unless value == '1'
    deployer.deploy!(name, false)
  end
  
  custom = File.file?(CUSTOM) ? File.read(CUSTOM) : nil
  deployer.run_builds!(:custom => custom)
  
  @projects = project_config
  @log = logger.messages
  erb :index
end

## GET /config
##
get '/config' do
  @projects = project_config
  @action   = 'config'
  @file     = CONFIG
  @contents = File.file?(@file) ? File.read(@file) : ''
  erb :config
end

## POST /config
##
post '/config' do
  @action   = 'config'
  @file     = CONFIG
  @contents = params[:contents]
  begin
    YAML.load(@contents)
    File.open(@file, 'w') { |f| f.write(@contents) }
  rescue
    @error = 'File not saved: invalid YAML'
  end
  @projects = project_config
  erb :config
end

## GET /custom
##
get '/custom' do
  @projects = project_config
  @action   = 'custom'
  @file     = CUSTOM
  @contents = File.file?(@file) ? File.read(@file) : ''
  erb :config
end

## POST /custom
##
post '/custom' do
  @projects = project_config
  @action   = 'custom'
  @file     = CUSTOM
  @contents = params[:contents]
  File.open(@file, 'w') { |f| f.write(@contents) }
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

