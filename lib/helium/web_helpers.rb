module Helium
  class Web
    
    helpers do
      # Returns the data structure contained in the app's deploy.yml file.
      def project_config
        File.file?(CONFIG) ? (YAML.load(File.read(CONFIG)) || {}) : {}
      end
      
      # Returns the list of IP addresses that have write access to the app.
      def allowed_ips
        File.file?(ACCESS) ? (YAML.load(File.read(ACCESS)) || []) : []
      end
      
      # Returns +true+ iff the request should be allowed write access.
      def allow_write_access?(env)
        allowed_ips.include?(env['REMOTE_ADDR'])
      end
      
      # Generic handler for displaying editable files requested using GET.
      def view_file(name)
        @error    = 'You are not authorized to edit this file' unless allow_write_access?(env)
        @projects = project_config
        @action   = name.to_s
        @file     = Web.const_get(name.to_s.upcase)
        @contents = File.file?(@file) ? File.read(@file) : ''
        erb :edit
      end
      
      # Shorthand for ERB's HTML-escaping method
      def h(string)
        ERB::Util.h(string)
      end
    end
    
  end
end

