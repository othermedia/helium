::APP_DIR = ::File.expand_path(::File.dirname(__FILE__))

require 'helium/web'

Helium::Web.configure do |config|
  config.allow_ips ['0.0.0.0', '127.0.0.1']
end

run Helium::Web
