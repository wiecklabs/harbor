require "rubygems"
require "pathname"
$:.unshift(Pathname(__FILE__).dirname.expand_path)
require "framework/router"
require "framework/application"
# require 