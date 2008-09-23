require "yaml"
require "thread"
require Pathname(__FILE__).dirname + "request"
require Pathname(__FILE__).dirname + "response"

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
    response = Response.new
    handler = @router.match(request)
    return not_found(request, response) if handler == false

    handler.call(request, response)
    [response.status, response.headers, response.string.to_a]
  rescue
    server_error($!, request, response)
  end

end
