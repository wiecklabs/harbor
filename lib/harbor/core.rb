require "rubygems"
require "pathname"

$:.unshift(Pathname(__FILE__).dirname.parent.expand_path.to_s)

require "harbor/version"
require "harbor/application"
require "harbor/support/array"
require "harbor/support/blank"
require "harbor/support/string"
require "harbor/container"
require "harbor/locale"
require "harbor/hooks"
require "harbor/file_store"
require "harbor/file"
require "harbor/checksum"
require "harbor/assets"
require "harbor/router"
require "harbor/plugin"
require "harbor/mime"
require "harbor/errors"
require "harbor/cache"
require "harbor/controller"
require "harbor/dispatcher"
require "harbor/consoles"
require "harbor/reloader"

class Harbor

  def initialize
    self.class::registered_applications.each do |application|
      applications << application.new
    end

    @dispatcher = Harbor::Dispatcher::instance
    config.helpers.register_all!
    config.reloader.populate_files if config.reloader.enabled?
  end

  def applications
    @applications ||= []
  end

  def dispatcher
    @dispatcher
  end

  def call(env)
    request = Request.new(self, env)
    response = Response.new(request)

    @dispatcher.dispatch!(request, response)

    response.to_a
  end

  def self.register_application(application)
    unless registered_applications.include? application
      application.instance_variable_set :@root, config.root.expand_path
      registered_applications << application
    end
  end

  def self.registered_applications
    @applications ||= []
  end
end

require "harbor/configuration"
require "harbor/autoloader"
