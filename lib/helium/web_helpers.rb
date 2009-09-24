module Helium
  class Web
    
    helpers do
      # Returns the data structure contained in the app's deploy.yml file.
      def project_config
        Deployer.new(File.dirname(CONFIG)).projects
      end
      
      # Returns the list of IP addresses that have write access to the app.
      def allowed_ips
        File.file?(ACCESS) ? (YAML.load(File.read(ACCESS)) || []) : []
      end
      
      # Returns +true+ iff the request should be allowed write access.
      def allow_write_access?(env)
        ip = (env['REMOTE_ADDR'] || '').scan(/(?:\d{1,3}\.){3}\d{1,3}/).flatten.first
        allowed_ips.include?(ip)
      end
      
      # Returns +true+ if a lock exists stopping other deploy processes running.
      def locked?
        File.file?(LOCK)
      end
      
      # Places a lock in the filesystem while running a code block. This is
      # used to make sure no more than one deploy process runs at once.
      def with_lock(&block)
        File.open(LOCK, 'w') { |f| f.write(Time.now.to_s) }
        at_exit { File.delete(LOCK) if File.exists?(LOCK) }
        result = block.call
        File.delete(LOCK) if File.exists?(LOCK)
        result
      end
      
      # Generic handler for displaying editable files requested using GET.
      def view_file(name)
        @error    = 'You are not authorized to edit this file' unless allow_write_access?(env)
        @projects = project_config
        @action   = name.to_s
        @file     = Helium::Web.const_get(name.to_s.upcase)
        @contents = File.file?(@file) ? File.read(@file) : ''
        erb :edit
      end
      
      # Markup for the web UI's logo
      def logotype
        '<span class="symbol">He</span>lium'
      end
      
      # Shorthand for ERB's HTML-escaping method
      def h(string)
        ERB::Util.h(string)
      end
      
      # Returns a disabled attribute if one is required
      def disabled?
        allow_write_access?(env) ? '' : 'disabled="disabled"'
      end
    end
    
  end
end

