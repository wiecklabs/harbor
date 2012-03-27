require "rubygems"
require "bundler/setup"
require "harbor"

config.load!(Pathname(__FILE__).dirname.parent + "env")

class <@= app_class @> < Harbor::Application

  def initialize
    # Any code you need to initialize your application goes here.
    # config is for data, your Application#initialize is for behavior.
    # For example, you might set config.connection_string in your config,
    # allowing you to overwrite it multiple times for different environments,
    # but you only actually want to initialize a database connection once,
    # so Sequel::connect(config.connection_string) would go in here.
    #
    # This method will be called when Harbor.new is called.
  end

end

Dir[Pathname(__FILE__).dirname.parent + 'controllers/*.rb'].each do |controller|
  require controller
end
