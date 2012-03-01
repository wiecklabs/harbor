require "rubygems"
require "pathname"

$:.unshift(Pathname(__FILE__).dirname.expand_path.to_s)

require "harbor/version"
require "harbor/support/array"
require "harbor/support/blank"
require "harbor/support/string"
require "harbor/container"
require "harbor/locale"
require "harbor/hooks"
require "harbor/file_store"
require "harbor/shellwords"
require "harbor/file"
require "harbor/checksum"
require "harbor/router"
require "harbor/application"
require "harbor/plugin"
require "harbor/mime"
require "harbor/errors"

require "harbor/cache"
require "harbor/controller"

module Harbor
  def self.env_path
    @env_path ||= Pathname(__FILE__).dirname.parent + "env"
  end

  def self.register_application(application)
    cascade << application.new
  rescue ArgumentError => e
    raise ArgumentError.new("#{application}: #{e.message}")
  end

  def self.router
    @router ||= Harbor::Router::instance
  end

  def self.call(env)
    request = Request.new(self, env)
    response = Response.new(request)

    catch(:abort_request) do
      if handler = cascade.detect { |application| application.match(request) }
        application.dispatch_request(handler, request, response)
      else
        request_path = (request.path_info[-1] == ?/) ? request.path_info[0..-2] : request.path_info
        if action = router.match(request.request_method, request_path)
          action.call(request, response)
        end
      end
    end

    response.to_a
  end

  private
  def self.cascade
    @cascade ||= []
  end
end

require "harbor/configuration"
