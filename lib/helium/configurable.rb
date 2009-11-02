module Helium
  module Configurable
    
    def configure
      yield(configuration)
    end
    
    def configuration
      @configuration ||= Configuration.new
    end
    alias :config :configuration
    
    class Configuration
      def initialize(hash = {})
        @options = {}.merge(hash)
      end
      
      def method_missing(name, value = nil)
        @options[name] = value unless value.nil?
        @options[name]
      end
    end
    
  end
end

