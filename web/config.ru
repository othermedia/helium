APP_DIR = File.expand_path(File.dirname(__FILE__))

require 'rubygems'
require 'helium/web'

run Sinatra::Application

