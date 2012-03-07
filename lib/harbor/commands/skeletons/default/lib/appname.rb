require "rubygems"
require "bundler/setup"
require "harbor"

config.load!(File.dirname(__FILE__).parent + "env")

class <$= app_class $> < Harbor::Application

  def initialize
    # Any code you need to initialize your application goes here.
  end

end

require Pathname(__FILE__).dirname + "<$= app_name $>/controllers/home"