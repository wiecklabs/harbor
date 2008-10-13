require "rubygems"
require "pathname"

$:.unshift(Pathname(__FILE__).dirname.expand_path)

require "wheels/router"
require "wheels/application"
require "wheels/public"