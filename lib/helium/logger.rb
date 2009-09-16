module Helium
  # Class to pick up log messages from the build process so we can display
  # them elsewhere, e.g. in web pages after deploy requests.
  class Logger
    attr_reader :messages
    def initialize
      @messages = []
    end
    
    def update(type, msg)
      @messages << msg
    end
  end
end

