require "rubygems"
require "pathname"

$:.unshift(Pathname(__FILE__).dirname.expand_path.to_s)

require "harbor/version"
require "harbor/support/array"
require "harbor/support/blank"
require "harbor/container"
require "harbor/locale"
require "harbor/hooks"
require "harbor/file_store"
require "harbor/shellwords"
require "harbor/file"
require "harbor/checksum"
require "harbor/router"
require "harbor/application"
require "harbor/cascade"
require "harbor/plugin"
require "harbor/mime"
require "harbor/errors"

require "harbor/cache"

module Harbor
  def self.env_path
    @env_path ||= Pathname(__FILE__).dirname.parent + "env"
  end
  
  def self.register_application(application)    
    cascade << application.new
  rescue ArgumentError => e
    raise ArgumentError.new("#{application}: #{e.message}")
  end
  
  def self.call(env)
    request = Request.new(self, env)
    response = Response.new(request)

    catch(:abort_request) do
      if handler = @cascade.detect { |application| application.match(request) }
        application.dispatch_request(handler, request, response)
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