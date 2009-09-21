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
    def initialize(path, output_dir = 'output')
      @path       = File.expand_path(path)
      @config     = join(@path, CONFIG_FILE)
      raise "Expected config file at #{@config}" unless File.file?(@config)
      @config     = YAML.load(File.read(@config))
      @output_dir = join(@path, output_dir)
    end
    
    # Runs all the deploy actions. If given a project name, only checkout out and builds
    # the given project, otherwise build all projects in `deploy.yml`.
    def run!(project = nil)
      return deploy!(project) if project
      @config.each { |project, url| deploy!(project, false) }
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
        url = @config[project]
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
        name = branch.name.split(SEP).last
        next if HEAD == name
        
        target = static_dir(project, name)
        
        log :export, "Exporting branch '#{ name }' of '#{ project }' into #{ target }"
        rm_rf(target) if File.directory?(target)
        cd(repo_dir) { `git checkout #{ branch.name }` }
        cp_r(repo_dir, target)
        rm_rf(join(target, GIT))
      end
    end
    
    # Scans all the checked-out projects for Jake build files and builds those projects
    # that have such a file. As the build progresses we use Jake event hooks to collect
    # dependencies and generated file paths, and when all builds are finished we generate
    # a JS.Packages file listing all the files discovered. This file should be included
    # in web pages to set up the the packages manager for loading our projects.
    def run_builds!(options = {})
      @tree    = Trie.new
      @custom  = options[:custom]
      @domain  = options[:domain]
      manifest = []
      
      # Loop over checked-out projects. Skip directories with no Jake file.
      Find.find(static_dir) do |path|
        next unless File.directory?(path) and File.file?(join(path, JAKE_FILE))
        project, branch = *path.split(SEP)[-2..-1]
        Jake.clear_hooks!
        
        # Event listener to capture file information from Jake
        hook = lambda do |build, package, build_type, file|
          if build_type == :min
            file = file.sub(path, '')
            manifest << join(project, branch, file)
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
      
      # Generate JS.Packages dependency file from ERB template and compress the result
      template = File.read(JS_CONFIG_TEMPLATE)
      code     = ERB.new(template, nil, ERB_TRIM_MODE).result(binding)
      packed   = Packr.pack(code, :shrink_vars => true)
      
      mkdir_p(static_dir)
      File.open(static_dir(PACKAGES), 'w') { |f| f.write(code) }
      File.open(static_dir(PACKAGES_MIN), 'w') { |f| f.write(packed) }
      
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
          rm_rf(path) unless @config.has_key?(entry)
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
    
    # Returns +true+ iff the set of files contains any dependency data.
    def has_manifest?(config)
      Trie === config ?
          config.any? { |path, conf| has_manifest?(conf) } :
          config.has_key?(:provides)
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
    
  end
end

