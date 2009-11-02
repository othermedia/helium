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
  
  ROOT          = File.expand_path(File.dirname(__FILE__))
  TEMPLATES     = File.join(ROOT, '..', 'templates')
  ERB_EXT       = '.erb'
  JS_CONFIG_TEMPLATE = File.join(TEMPLATES, 'packages.js.erb')
  
  CONFIG_FILE   = 'deploy.yml'
  REPOS         = 'repos'
  STATIC        = 'static'
  PACKAGES      = 'helium-src.js'
  PACKAGES_MIN  = 'helium.js'
  WEB_ROOT      = 'js'
  
  GIT           = '.git'
  HEAD          = 'HEAD'
  
  JS_CLASS      = 'js.class'
  LOADER_FILE   = 'loader.js'
  JAKE_FILE     = Jake::CONFIG_FILE
  
  SEP  = File::SEPARATOR
  BYTE = 1024.0
  
  ERB_TRIM_MODE = '-'
  
  %w[trie configurable deployer generator logger].each do |file|
    require File.join(ROOT, 'helium', file)
  end
  
  def self.generate(template, dir, options = {})
    Generator.new(template, dir, options).run!
  end
  
end

