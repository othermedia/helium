require 'fileutils'
require 'rubygems'
require 'sinatra'
require 'yaml'

ROOT_DIR = File.dirname(__FILE__)
require File.join(ROOT_DIR, '..', 'helium')
require File.join(ROOT_DIR, 'web_helpers')

LIB_DIR  = 'lib'
CONFIG   = File.join(APP_DIR, 'deploy.yml')
CUSTOM   = File.join(APP_DIR, 'custom.js')
ACCESS   = File.join(APP_DIR, 'access.yml')
PUBLIC   = File.join(APP_DIR, 'public', 'js')

set :public, File.join(APP_DIR, 'public')

## Home page -- just loads the project list and renders.
get '/' do
  @projects = project_config
  @domain   = env['HTTP_HOST']
  erb :index
end

## Deploys all selected projects and renders a list of log messages.
post '/deploy' do
  if allow_write_access?(env)
    deployer = Helium::Deployer.new(APP_DIR, LIB_DIR)
    logger   = Helium::Logger.new
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
    
    @log = logger.messages
  else
    @error = 'You are not authorized to run deployments'
  end
  @projects = project_config
  erb :index
end

get('/config') { view_file :config }

## Save changes to the configuration file, making sure it validates as YAML.
post '/config' do
  @action   = 'config'
  @file     = CONFIG
  @contents = params[:contents]
  if allow_write_access?(env)
    begin
      data = YAML.load(@contents)
      raise 'invalid' unless Hash === data
      File.open(@file, 'w') { |f| f.write(@contents) }
    rescue
      @error = 'File not saved: invalid YAML'
    end
  else
    @error = 'You are not authorized to edit this file'
  end
  @projects = project_config
  erb :edit
end

get('/custom') { view_file :custom }

## Save changes to the custom loaders file.
post '/custom' do
  @action   = 'custom'
  @file     = CUSTOM
  @contents = params[:contents]
  if allow_write_access?(env)
    File.open(@file, 'w') { |f| f.write(@contents) }
  else
    @error = 'You are not authorized to edit this file'
  end
  @projects = project_config
  erb :edit
end

