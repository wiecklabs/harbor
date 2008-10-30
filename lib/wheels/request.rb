require "rack/request"
require Pathname(__FILE__).dirname + "session"

module Wheels
  class Request < Rack::Request

    attr_reader :application

    def initialize(application, env)
      raise ArgumentError.new("+env+ must be a Rack Environment Hash") unless env.is_a?(Hash)
      @application = application
      super(env)
    end

    def session
      @session ||= Session.new(self)
    end

    def request_method
      @env['REQUEST_METHOD'] = params['_method'].upcase if request_method_in_params?
      @env['REQUEST_METHOD']
    end

    def environment
      @env['APP_ENVIRONMENT'] || (@application ? @application.environment : "development")
    end

    private
    def request_method_in_params?
      @env["REQUEST_METHOD"] == "POST" && %w(PUT DELETE).include?((params['_method'] || "").upcase)
    end
  end
end