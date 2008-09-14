require "rubygems"
require "erubis"
require "stringio"
require "rack/request"

module Rack
  class Request
    def request_method
      @env['REQUEST_METHOD'] = params['_method'].upcase if request_method_in_params?
      @env['REQUEST_METHOD']
    end

    private
    def request_method_in_params?
      @env["REQUEST_METHOD"] == "POST" && %w(PUT DELETE).include?((params['_method'] || "").upcase)
    end
  end
end

class Router

  URI_CHAR = '[^/?:,&#\.]'.freeze unless defined?(URI_CHAR)
  PARAM = /(:(#{URI_CHAR}+))/.freeze unless defined?(PARAM)

  attr_accessor :routes

  def initialize(&routes)
    @routes = []
    @route_match_cache = {}
    instance_eval(&routes) if block_given?
  end

  # Matches a GET request
  def get(matcher, &handler)
    register(:get, matcher, &handler)
  end

  # Matches a POST (create) request
  def post(matcher, &handler)
    register(:post, matcher, &handler)
  end

  # Matches a PUT (update) request
  def put(matcher, &handler)
    register(:put, matcher, &handler)
  end

  # Matches a DELETE request
  def delete(matcher, &handler)
    register(:delete, matcher, &handler)
  end

  def register(request_method, matcher, &handler)
    @routes << [request_method.to_s.upcase, transform(matcher), handler]
  end

  def clear
    @routes = []
  end

  def match(request)
    # TODO: this cache key probably needs to be beefed up
    @route_match_cache["#{request.request_method}_#{request.path_info}"] ||= (route = @routes.detect do |request_method, matcher, handler|
      next unless request.request_method == request_method
      next unless matcher.call(request)
      handler
    end ) ? route[2] : false
  end

  private

  def transform(matcher)
    case matcher
    when Proc then matcher
    when Regexp then lambda { |request| request.path_info =~ matcher }
    when String
      param_keys = []
      regex = matcher.gsub(PARAM) { param_keys << $2; "(#{URI_CHAR}+)" }
      regex = /^#{regex}$/
      lambda do |request|
        if request.path_info =~ regex
          request.params.update(Hash[*param_keys.zip($~.captures).flatten])
        end
      end
    end
  end

end

class Response < StringIO

  attr_accessor :application, :status, :content_type, :headers

  def initialize(application)
    @application = application
    @headers = {}
    @content_type = "text/html"
    @status = 200
    super("")
  end

  def headers
    @headers.merge({
      "Content-Type" => self.content_type,
      "Content-Length" => self.size.to_s
    })
  end

  def render(file, context = nil)
    self << Erubis::FastEruby.new(File.read(file)).evaluate(context)
  end
end

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
    [response.status, response.headers, response.string.to_a]
  end

  def call(env)
    request = Rack::Request.new(env)
    response = Response.new(self)
    handler = @router.match(request)
    return not_found(request, response) if handler == false
    handler.call(request, response)
    [response.status, response.headers, response.string.to_a]
  rescue
    server_error($!, request, response)
  end
end