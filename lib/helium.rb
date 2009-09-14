require 'observer'
require 'erb'
require 'yaml'
require 'fileutils'
require 'find'

require 'rubygems'
require 'grit'
require 'jake'
require 'packr'
require 'oyster'

module Helium
  
  VERSION = '0.1.0'
  
  ROOT          = File.dirname(__FILE__)
  CONFIG_FILE   = 'deploy.yml'
  REPOS         = 'repos'
  STATIC        = 'static'
  JS_CONFIG_TEMPLATE = 'packages.js.erb'
  PACKAGES      = 'packages-src.js'
  PACKAGES_MIN  = 'packages.js'
  GIT           = '.git'
  HEAD          = 'HEAD'
  JAKE_FILE     = Jake::CONFIG_FILE
  
  SEP  = File::SEPARATOR
  BYTE = 1024.0
  
  ERB_TRIM_MODE = '-'
  
  require File.join(ROOT, 'helium', 'trie')
  require File.join(ROOT, 'helium', 'deployer')
  
end

