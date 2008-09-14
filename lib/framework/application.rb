require "yaml"
require 'thread'
require "lib/framework/request"
require "lib/framework/response"

class Application
  def initialize(router)
    @router = router
  end

  def not_found(request, response)
    response.flush
    response.status = 404
    response.puts "The page you requested could not be found"
    [response.status, response.headers, response.string.to_a]
  end

  def server_error(error, request, response)
    response.flush
    response.status = 500
    response.puts error
    response.puts error.backtrace
    response.puts request.to_yaml
    [response.status, response.headers, response.string.to_a]
  end

  def call(env)
    request = Rack::Request.new(env)
    response = Response.new(self)
    handler = @router.match(request)
    return not_found(request, response) if handler == false

    dispatcher = Thread.new do
      handler.call(request, response)
    end

    dispatcher.join
    [response.status, response.headers, response.string.to_a]
  rescue
    server_error($!, request, response)
  end

end