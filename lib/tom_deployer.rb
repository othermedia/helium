require 'rubygems'
require 'yaml'
require 'jake'
require 'grit'

class TomDeployer
  VERSION = '0.1.0'
  
  CONFIG_FILE = 'deploy.yml'
  REPOS       = 'repos'
  STATIC      = 'static'
  GIT         = '.git'
  
  def initialize(path)
    @path = path
    @config = join(path, CONFIG_FILE)
    raise "Expected config file at #{@config}" unless File.file?(@config)
    @config = YAML.load(File.read(@config))
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
  end
  
  def join(*args)
    File.join(*args)
  end
  
  def method_missing(*args, &block)
    FileUtils.__send__(*args, &block)
  end
end

