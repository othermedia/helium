require 'rubygems'
require 'yaml'
require 'grit'
require 'jake'
require 'packr'
require 'oyster'
require 'erb'

class TomDeployer
  VERSION = '0.1.0'
  
  ROOT        = File.dirname(__FILE__)
  CONFIG_FILE = 'deploy.yml'
  REPOS       = 'repos'
  STATIC      = 'static'
  PACKAGES    = 'packages.js'
  GIT         = '.git'
  
  require File.join(ROOT, 'trie')
  
  def initialize(path)
    @path = File.expand_path(path)
    @config = join(path, CONFIG_FILE)
    raise "Expected config file at #{@config}" unless File.file?(@config)
    @config = YAML.load(File.read(@config))
    
    Jake.clear_hooks!
    
    @deps = {}
    jake_hook :file_created do |package, build, path|
      @deps[path] = package.meta if build == :min
    end
  end
  
  def run!(output_dir = 'output')
    output_dir = join(@path, output_dir)
    
    mkdir_p(output_dir)
    mkdir_p(join(output_dir, REPOS))
    mkdir_p(join(output_dir, STATIC))
    
    @config.each do |name, url|
      repo_dir = join(output_dir, REPOS, name)
      checkout(url, repo_dir)
      
      repo = Grit::Repo.new(repo_dir)
      repo.remotes.each do |remote|
        export(name, repo_dir, remote.name, join(output_dir, STATIC))
      end
    end
    
    generate_config!(join(output_dir, STATIC))
  end
  
  def generate_config!(dir)
    @tree = Trie.new
    
    @deps.each do |path, config|
      path  = path.gsub(dir, '').gsub(/\/(\.\/)*/, '/')
      parts = path.scan(/[^\/]+/)
      key   = parts[0..1] + [parts[2..-1] * '']
      @tree[key] = config
    end
    
    File.open(join(dir, PACKAGES), 'w') do |f|
      template = File.read(join(ROOT, 'packages.js.erb'))
      packages = ERB.new(template).result(binding)
      packed   = Packr.pack(packages, :shrink_vars => true)
      f.write(packages)
    end
  end
  
  def checkout(url, dir)
    puts "Checking out #{url} into #{dir}"
    if File.directory?(dir)
      cd(dir) { `git fetch origin` }
    else
      `git clone #{url} #{dir}`
    end
  end
  
  def export(project, repo_dir, remote, static_dir)
    branch = remote.split('/').last
    target = join(static_dir, project, branch)
    
    rm_rf(target) if File.directory?(target)
    mkdir_p(join(static_dir, project))
    
    puts "Exporting #{project}:#{remote} into #{target}"
    
    cd(repo_dir) { `git checkout #{remote}` }
    cp_r(repo_dir, target)
    rm_rf(join(target, GIT))
    
    Jake.build!(target) if File.file?(join(target, 'jake.yml'))
  end
  
private
  
  def join(*args)
    File.join(*args)
  end
  
  def method_missing(*args, &block)
    FileUtils.__send__(*args, &block)
  end
end

