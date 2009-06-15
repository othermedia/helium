require 'rubygems'
require 'rack'
require File.dirname(__FILE__) + '/app'

run Sinatra::Application

