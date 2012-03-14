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
require "harbor/router"
require "harbor/plugin"
require "harbor/mime"
require "harbor/errors"

require "harbor/cache"
require "harbor/controller"

require "harbor/dispatcher"

require "harbor/consoles"

module Harbor
  def self.dispatcher
    @dispatcher ||= Harbor::Dispatcher::instance
  end

  def self.call(env)
    request = Request.new(self, env)
    response = Response.new(request)

    catch(:abort_request) do
      dispatcher.dispatch!(request, response)
    end

    response.to_a
  end

  private
  def self.applications
    @applications ||= []
  end
end

require "harbor/configuration"
