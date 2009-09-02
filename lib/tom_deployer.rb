require 'observer'
require 'erb'
require 'yaml'
require 'fileutils'
require 'find'

require 'rubygems'
require 'grit'
require 'jake'
require 'packr'
require 'oyster'

class TomDeployer
  include Observable
  
  VERSION = '0.1.0'
  
  ROOT        = File.dirname(__FILE__)
  CONFIG_FILE = 'deploy.yml'
  JS_CONFIG_TEMPLATE = 'packages.js.erb'
  REPOS       = 'repos'
  STATIC      = 'static'
  PACKAGES    = 'packages.js'
  GIT         = '.git'
  HEAD        = 'HEAD'
  JAKE_FILE   = Jake::CONFIG_FILE
  
  SEP  = File::SEPARATOR
  BYTE = 1024.0
  
  ERB_TRIM_MODE = '-'
  
  require File.join(ROOT, 'trie')
  
  def initialize(path, output_dir = 'output')
    @path       = File.expand_path(path)
    @config     = join(@path, CONFIG_FILE)
    raise "Expected config file at #{@config}" unless File.file?(@config)
    @config     = YAML.load(File.read(@config))
    @output_dir = join(@path, output_dir)
  end
  
  def run!(project = nil)
    return deploy!(project) if project
    @config.each { |project, url| deploy!(project, false) }
    run_builds!
  end
  
  def deploy!(project, build = true)
    checkout(project)
    export(project)
    run_builds! if build
  end
  
  def checkout(project)
    dir = repo_dir(project)
    if File.directory?(join(dir, GIT))
      log :git_fetch, "Updating Git repo in #{ dir }"
      cd(dir) { `git fetch origin` }
    else
      url = @config[project]
      log :git_clone, "Cloning Git repo #{ url } into #{ dir }"
      `git clone #{ url } #{ dir }`
    end
  end
  
  def export(project)
    repo_dir = repo_dir(project)
    repo     = Grit::Repo.new(repo_dir)
    branches = repo.remotes + repo.tags
    
    mkdir_p(static_dir(project))
    
    branches.each do |branch|
      name   = branch.name.split(SEP).last
      next if HEAD == name
      
      target = static_dir(project, name)
      
      log :export, "Exporting branch '#{ name }' of '#{ project }' into #{ target }"
      rm_rf(target) if File.directory?(target)
      cd(repo_dir) { `git checkout #{ branch.name }` }
      cp_r(repo_dir, target)
      rm_rf(join(target, GIT))
    end
  end
  
  def run_builds!
    @tree = Trie.new
    Find.find(static_dir) do |path|
      next unless File.directory?(path) and File.file?(join(path, JAKE_FILE))
      project, branch = *path.split(SEP)[-2..-1]
      Jake.clear_hooks!
      
      hook = lambda do |build, package, build_type, file|
        if build_type == :min
          file = file.gsub(/\/(\.?\/)*/, SEP).gsub(path, '')
          key = [project, branch, file]
          @tree[key] = package.meta
        end
      end
      jake_hook(:file_created, &hook)
      jake_hook(:file_not_changed, &hook)
      
      log :jake_build, "Building branch '#{ branch }' of '#{ project }' from #{ join(path, JAKE_FILE) }"
      
      begin
        Jake.build!(path)
      rescue
      end
    end
    
    File.open(static_dir(PACKAGES), 'w') do |f|
      template = File.read(join(ROOT, JS_CONFIG_TEMPLATE))
      code     = ERB.new(template, nil, ERB_TRIM_MODE).result(binding)
      f.write(code)
    end
  end
    
private
  
  def repo_dir(project)
    join(@output_dir, REPOS, project)
  end
  
  def static_dir(project = nil, branch = nil)
    path = [@output_dir, STATIC, project, branch].compact
    join(*path)
  end
  
  def log(*args)
    changed(true)
    notify_observers(*args)
  end
  
  def join(*args)
    File.join(*args)
  end
  
  def method_missing(*args, &block)
    FileUtils.__send__(*args, &block)
  end
end

