require 'helium'

Helium::Web.configure do |config|
  config.app_dir File.dirname(__FILE__)
  config.allow_ips ['0.0.0.0', '127.0.0.1']
end

run Helium::Web
