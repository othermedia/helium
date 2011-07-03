require 'fileutils'
require 'sinatra/base'
require 'yaml'

module Helium
  class Web < Sinatra::Base
    extend Configurable
    
    ROOT_DIR = File.expand_path(File.dirname(__FILE__))
    require File.join(ROOT_DIR, 'web_helpers')
    
    CONFIG  = 'deploy.yml'
    CUSTOM  = 'custom.js'
    LIB_DIR = 'lib'
    LOCK    = '.lock'
    PUBLIC  = File.join('public', WEB_ROOT)
    
    set :static, true
    set :views, File.join(ROOT_DIR, 'views')
    
    before do
      self.class.set :public, File.join(app_directory, 'public')
      @projects = project_config
      @location = get_location
    end
    
    ## Home page -- just loads the project list and renders.
    get('/') { erb :index }
    
    ## Rendered if a missing script file is requested.
    get "/#{WEB_ROOT}/*" do
      @path = params[:splat].first
      halt 404, erb(:missing)
    end
    
    ## Deploys all selected projects and renders a list of log messages.
    post '/app/deploy' do
      if not allow_write_access?(env)
        @error = 'You are not authorized to run deployments'
      elsif locked?
        @error = 'Deployment already in progress'
      end
      
      halt(200, erb(:deploy)) if @error
      
      with_lock do
        deployer = Helium::Deployer.new(app_directory, LIB_DIR)
        logger   = Helium::Logger.new
        deployer.add_observer(logger)
        
        params[:projects].each do |name, value|
          next unless value == '1'
          deployer.deploy!(name, false)
        end
        
        deployer.cleanup!
        
        custom_path = File.join(app_directory, CUSTOM)
        public_path = File.join(app_directory, PUBLIC)
        
        custom = File.file?(custom_path) ? File.read(custom_path) : nil
        
        begin
          files = deployer.run_builds!(:custom => custom, :location => @location)
        rescue => e
          @error = e.message
          halt(200, erb(:deploy))
        end
        
        FileUtils.rm_rf(public_path) if File.exists?(public_path)
        
        files.each do |path|
          source, dest = File.join(deployer.static_dir, path), File.join(public_path, path)
          next unless File.file?(source)
          FileUtils.mkdir_p(File.dirname(dest))
          FileUtils.cp(source, dest)
        end
        
        @log = logger.messages.map { |msg| msg.sub(File.join(app_directory, LIB_DIR), '') }
        erb :deploy
      end
    end
    
    get('/app/config') { view_file :config }
    
    ## Save changes to the configuration file, making sure it validates as YAML.
    post '/app/config' do
      @action   = 'config'
      @file     = File.join(app_directory, CONFIG)
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
    
    get('/app/custom') { view_file :custom }
    
    ## Save changes to the custom loaders file.
    post '/app/custom' do
      @action   = 'custom'
      @file     = File.join(app_directory, CUSTOM)
      @contents = params[:contents]
      if allow_write_access?(env)
        File.open(@file, 'w') { |f| f.write(@contents) }
      else
        @error = 'You are not authorized to edit this file'
      end
      erb :edit
    end
    
    ## Catch requests for public files and serve them from the gem
    get '/*' do
      send_file(File.join(ROOT_DIR, 'public', env['PATH_INFO']))
    end
    
  end
end

