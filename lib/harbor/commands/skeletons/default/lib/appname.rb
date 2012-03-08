require "rubygems"
require "bundler/setup"
require "harbor"

config.load!(Pathname(__FILE__).dirname.parent + "env")

class <@= app_class @> < Harbor::Application

  def initialize
    # Any code you need to initialize your application goes here.
  end

end

require_relative "../controllers/home"
