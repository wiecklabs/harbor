require "rack/request"
require Pathname(__FILE__).dirname + "session"

module Wheels
  class Request < Rack::Request

    attr_accessor :layout
    attr_reader :application

    def initialize(application, env)
      raise ArgumentError.new("+env+ must be a Rack Environment Hash") unless env.is_a?(Hash)
      @application = application
      super(env)
    end

    def session
      @session ||= Wheels::Session.new(self)
    end

    def session?
      @session
    end

    def layout
      defined?(@layout) ? @layout : application.default_layout
    end

    def remote_ip
      env["REMOTE_ADDR"] || env["HTTP_CLIENT_IP"] || env["HTTP_X_FORWARDED_FOR"]
    end

    def request_method
      @env['REQUEST_METHOD'] = self.POST['_method'].upcase if request_method_in_params?
      @env['REQUEST_METHOD']
    end

    def environment
      @env['APP_ENVIRONMENT'] || (@application ? @application.environment : "development")
    end

    private
    def request_method_in_params?
      @env["REQUEST_METHOD"] == "POST" && self.POST && %w(PUT DELETE).include?((self.POST['_method'] || "").upcase)
    end
  end
end