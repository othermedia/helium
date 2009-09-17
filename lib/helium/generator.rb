module Helium
  # The +Generator+ class is used by the command-line tools to create copies of
  # the web app and the JavaScript project template. It copies the contents of
  # one of the +template+ directories into a local directory, expanding any files
  # with .erb extensions as ERB templates.
  # 
  # For example, a file <tt>jake.yml.erb</tt> will be copied into the target dir as
  # <tt>jake.yml</tt> after being evaluated using ERB.
  # 
  # If a filename contains variable names enclosed in double-underscores, the
  # resulting copy will have those replaced by the value of the named instance
  # variable. For example, <tt>__name__.js</tt> will be copied to <tt>myproj.js</tt>
  # if <tt>@name = 'myproj'</tt>.
  # 
  class Generator
    
    # Generators are initialized using the name of the template (a collection of
    # files in the +templates+ directory, a target directory and an option hash.
    # Keys in the option hash become instance variables accessible to ERB templates.
    def initialize(template, dir, options = {})
      options.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      @_source    = join(TEMPLATES, template)
      @_directory = expand_path(dir)
    end
    
    # Runs the generator, copying all files as required. All ERB/name replacement
    # is handled in this method.
    def run!
      Find.find(@_source) do |path|
        next unless file?(path)
        content = read(path)
        
        # Replace variable names in file paths
        path = path.sub(@_source, '').gsub(/__(.+?)__/) { instance_variable_get("@#{$1}") }
        target = join(@_directory, path)
        
        # Evaluate using ERB if required
        if extname(path) == ERB_EXT
          content = ERB.new(content).result(binding)
          target  = join(dirname(target), basename(target, ERB_EXT))
        end
        
        # Generate destination file
        FileUtils.mkdir_p(dirname(target))
        open(target, 'w') { |f| f.write(content) }
      end
    end
    
    # Provide shorthand access to all +File+ methods.
    def method_missing(*args, &block)
      File.__send__(*args, &block)
    end
    
    # Returns a camelcased copy of the string, for example:
    # 
    #   camelize('my-project')
    #   #=> 'MyProject'
    # 
    def camelize(string)
      string.gsub(/^(.)/) { $1.upcase }.
             gsub(/[\s\-\_](.)/) { $1.upcase }
    end
    
  end
end

