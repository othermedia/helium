module Helium
  # The +Deployer+ class is responsible for performing all of Helium's central functions:
  # downloading projects from Git, exporting static copies of branches, building projects
  # using Jake and generating the dependency file.
  # 
  # To run, the class requires a file called `deploy.yml` in the target directory, listing
  # projects with their Git URLs. (See tests and README for examples.)
  # 
  class Deployer
    include Observable
    
    # Initialize using the directory containing the `deploy.yml` file, and the name of
    # the directory to export repositories and static files to.
    # 
    #   deployer = Helium::Deployer.new('path/to/app', 'js')
    # 
    def initialize(path, output_dir = 'output', options = {})
      @path       = File.expand_path(path)
      @config     = join(@path, CONFIG_FILE)
      raise "Expected config file at #{@config}" unless File.file?(@config)
      @output_dir = join(@path, output_dir)
      @options    = options
    end
    
    # Returns a hash of projects names and their Git URLs.
    def projects
      return @projects if defined?(@projects)
      
      data = YAML.load(File.read(@config))
      raise "No configuration for JS.Class" unless js_class = data[JS_CLASS]
      @jsclass_version = js_class['version']
      
      @projects = data['projects'] || {}
      @projects[JS_CLASS] = js_class['repository']
      @projects
    end
    
    # Runs all the deploy actions. If given a project name, only checkout out and builds
    # the given project, otherwise build all projects in `deploy.yml`.
    def run!(project = nil)
      return deploy!(project) if project
      projects.each { |project, url| deploy!(project, false) }
      run_builds!
    end
    
    # Deploys an individual project by checking it out from Git, exporting static copies
    # of all its branches and building them using Jake.
    def deploy!(project, build = true)
      checkout(project)
      export(project)
      run_builds! if build
    end
    
    # Checks out (or updates if already checked out) a project by name from its Git
    # repository. If the project is new, we use `git clone` to copy it, otherwise
    # we use `git fetch` to update it.
    def checkout(project)
      dir = repo_dir(project)
      if File.directory?(join(dir, GIT))
        log :git_fetch, "Updating Git repo in #{ dir }"
        cd(dir) { `git fetch origin` }
      else
        url = projects[project]
        log :git_clone, "Cloning Git repo #{ url } into #{ dir }"
        `git clone #{ url } "#{ dir }"`
      end
    end
    
    # Exports static copies of a project from every branch and tag in its Git repository.
    # Existing static copies on disk are destroyed and replaced.
    def export(project)
      repo_dir = repo_dir(project)
      repo     = Grit::Repo.new(repo_dir)
      branches = repo.remotes + repo.tags
      
      mkdir_p(static_dir(project))
      
      branches.each do |branch|
        name, commit = branch.name.split(SEP).last, branch.commit.id
        next if HEAD == name
        
        target = static_dir(project, commit)
        
        log :export, "Exporting branch '#{ name }' of '#{ project }' into #{ target }"
        rm_rf(target) if File.directory?(target)
        cp_r(repo_dir, target)
        
        cd(target) {
          if repo.branches.map { |b| b.name }.include?(name)
            `git checkout #{ name }`
            `git merge #{ branch.name }`
          else
            `git checkout -b #{ name } #{ branch.name }`
          end
        }
      end
    end
    
    # Scans all the checked-out projects for Jake build files and builds those projects
    # that have such a file. As the build progresses we use Jake event hooks to collect
    # dependencies and generated file paths, and when all builds are finished we generate
    # a JS.Packages file listing all the files discovered. This file should be included
    # in web pages to set up the the packages manager for loading our projects.
    def run_builds!(options = nil)
      options ||= @options
      
      @tree    = Trie.new
      @custom  = options[:custom]
      @domain  = options[:domain]
      manifest = []
      
      # Loop over checked-out projects. Skip directories with no Jake file.
      Find.find(static_dir) do |path|
        next unless File.directory?(path) and File.file?(join(path, JAKE_FILE))
        
        project, commit = *path.split(SEP)[-2..-1]
        branch = Grit::Repo.new(path).head.name
        Jake.clear_hooks!
        
        # Event listener to capture file information from Jake
        hook = lambda do |build, package, build_type, file|
          if build_type == :min
            @js_loader = file if File.basename(file) == LOADER_FILE and
                                 project == JS_CLASS and
                                 branch  == @jsclass_version
            
            file = file.sub(path, '')
            manifest << join(project, commit, file)
            @tree[[project, branch]] = commit
            @tree[[project, branch, file]] = package.meta
          end
        end
        jake_hook(:file_created, &hook)
        jake_hook(:file_not_changed, &hook)
        
        log :jake_build, "Building branch '#{ branch }' of '#{ project }' from #{ join(path, JAKE_FILE) }"
        
        begin; Jake.build!(path)
        rescue; end
      end
      
      generate_manifest!
      manifest + [PACKAGES, PACKAGES_MIN]
    end
    
    # Removes any repositories and static files for projects not listed in the the
    # `deploy.yml` file.
    def cleanup!
      [repo_dir, static_dir].each do |dir|
        next unless File.directory?(dir)
        (Dir.entries(dir) - %w[. ..]).each do |entry|
          path = join(dir, entry)
          next unless File.directory?(path)
          rm_rf(path) unless projects.has_key?(entry)
        end
      end
    end
    
    # Returns the path to the Git repository for a given project.
    def repo_dir(project = nil)
      path = [@output_dir, REPOS, project].compact
      join(*path)
    end
    
    # Returns the path to the static export directory for a given project and branch.
    def static_dir(project = nil, branch = nil)
      path = [@output_dir, STATIC, project, branch].compact
      join(*path)
    end
      
  private
    
    # Generates JS.Packages dependency file from ERB template and compresses the result
    def generate_manifest!
      template = File.read(JS_CONFIG_TEMPLATE)
      code     = ERB.new(template, nil, ERB_TRIM_MODE).result(binding)
      packed   = Packr.pack(code, :shrink_vars => true)
      
      mkdir_p(static_dir)
      File.open(static_dir(PACKAGES), 'w') { |f| f.write(code) }
      File.open(static_dir(PACKAGES_MIN), 'w') { |f| f.write(packed) }
    end
    
    # Returns +true+ iff the set of files contains any dependency data.
    def has_manifest?(config)
      case config
      when Trie then config.any? { |path, conf| has_manifest?(conf) }
      when Hash then config.has_key?(:provides)
      else nil
      end
    end
    
    # Notifies observers by sending a log message.
    def log(*args)
      changed(true)
      notify_observers(*args)
    end
    
    # Shorthand for <tt>File.join</tt>
    def join(*args)
      File.join(*args)
    end
    
    # We use +method_missing+ to create shorthands for +FileUtils+ methods.
    def method_missing(*args, &block)
      FileUtils.__send__(*args, &block)
    end
    
    def `(command)
      puts command
      system(command)
    end
    
  end
end

