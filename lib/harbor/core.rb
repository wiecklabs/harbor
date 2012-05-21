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

  def self.serve_public_files!(root)
    # This will make sure a single public folder is served among all registered
    # applications / ports, last registered one wins.
    @public_files ||=
      begin
        files = PublicFiles.new
        Dispatcher::instance.cascade << files
        files
      end
    @public_files.root = root
  end

  private

  # TODO: Check if we can use Rack::File
  class PublicFiles
    def root=(root)
      @root = root
    end

    def match(request)
      file = request.path_info
      path = "#{@root}/#{file}"

      ::File.exist?(path) && ::File.readable?(path)
    end

    def call(request, response)
      file = request.path_info
      path = "#{@root}/#{file}"
      response.cache(nil, ::File.mtime(path), 86400) do
        response.stream_file(path)
      end
    end
  end
end

require "harbor/configuration"
require "harbor/autoloader"
