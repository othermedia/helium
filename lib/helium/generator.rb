module Helium
  class Generator
    
    def initialize(template, dir, options = {})
      options.each do |key, value|
        instance_variable_set("@#{key}", value)
      end
      @_source    = join(TEMPLATES, template)
      @_directory = expand_path(dir)
    end
    
    def run!
      Find.find(@_source) do |path|
        next unless file?(path)
        content = read(path)
        target  = join(@_directory, path.sub(@_source, ''))
        
        target.gsub!(/__([^_]+)__/) { instance_variable_get("@#{$1}") }
        
        if extname(path) == ERB_EXT
          content = ERB.new(content).result(binding)
          target  = join(dirname(target), basename(target, ERB_EXT))
        end
        
        FileUtils.mkdir_p(dirname(target))
        open(target, 'w') { |f| f.write(content) }
      end
    end
    
    def method_missing(*args, &block)
      File.__send__(*args, &block)
    end
    
    def camelize(string)
      string.gsub(/^(.)/) { $1.upcase }.
             gsub(/[\s\-\_](.)/) { $1.upcase }
    end
    
  end
end

