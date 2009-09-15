require 'fileutils'
require 'rubygems'
require 'sinatra'
require 'yaml'

require File.join(File.dirname(__FILE__), '..', 'helium')

LIB_DIR  = 'lib'
CONFIG   = File.join(APP_DIR, 'deploy.yml')
CUSTOM   = File.join(APP_DIR, 'custom.js')
PUBLIC   = File.join(APP_DIR, 'public', 'js')

set :public, File.join(APP_DIR, 'public')

# Returns the data structure contained in the app's deploy.yml file.
def project_config
  File.file?(CONFIG) ? YAML.load(File.read(CONFIG)) : {}
end

# Generic handler for displaying editable files requested using GET.
def view_file(name)
  @projects = project_config
  @action   = name.to_s
  @file     = Kernel.const_get(name.to_s.upcase)
  @contents = File.file?(@file) ? File.read(@file) : ''
  erb :edit
end

## GET /
## Home page -- just loads the project list and renders.
get '/' do
  @projects = project_config
  @domain   = env['HTTP_HOST']
  erb :index
end

## POST /deploy
## Deploys all selected projects and renders a list of log messages.
post '/deploy' do
  deployer = Helium::Deployer.new(APP_DIR, LIB_DIR)
  logger   = Logger.new
  deployer.add_observer(logger)
  
  params[:projects].each do |name, value|
    next unless value == '1'
    deployer.deploy!(name, false)
  end
  
  custom = File.file?(CUSTOM) ? File.read(CUSTOM) : nil
  files = deployer.run_builds!(:custom => custom)
  
  FileUtils.rm_rf(PUBLIC) if File.exists?(PUBLIC)
  
  files.each do |path|
    source, dest = File.join(deployer.static_dir, path), File.join(PUBLIC, path)
    FileUtils.mkdir_p(File.dirname(dest))
    FileUtils.cp(source, dest)
  end
  
  @projects = project_config
  @log = logger.messages
  erb :index
end

## GET /config
get('/config') { view_file :config }

## POST /config
## Save changes to the configuration file, making sure it validates as YAML.
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
  erb :edit
end

## GET /custom
get('/custom') { view_file :custom }

## POST /custom
## Save changes to the custom loaders file.
post '/custom' do
  @projects = project_config
  @action   = 'custom'
  @file     = CUSTOM
  @contents = params[:contents]
  File.open(@file, 'w') { |f| f.write(@contents) }
  erb :edit
end

# Class to pick up log messages from the build process so we can display
# them to the user on completion.
class Logger
  attr_reader :messages
  def initialize
    @messages = []
  end
  
  def update(type, msg)
    @messages << msg.sub(File.join(APP_DIR, LIB_DIR), '')
  end
end

