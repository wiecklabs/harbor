gem "rack", "~> 0.4.0"
require "rack"

require "yaml"
require "thread"

require Pathname(__FILE__).dirname + "rack/utils"
require Pathname(__FILE__).dirname + "request"
require Pathname(__FILE__).dirname + "response"
require Pathname(__FILE__).dirname + "block_io"

module Wheels
  class Application

    def self.routes(services = self.class.services)
      raise NotImplementedError.new("Your application must redefine #{self}#routes.")
    end

    def self.services=(container)
      @services = container
    end

    def self.services
      @services ||= Wheels::Container.new
    end

    attr_reader :environment, :logger

    def initialize(router = self.class.routes, environment = ENV["ENVIRONMENT"])
      @router = router
      @environment = (environment || "development").to_s
      @logger = self.class.services.get("logger") rescue nil
    end

    def default_layout
      "layouts/application"
    end

    def call(env)
      env["APP_ENVIRONMENT"] = environment
      request = Request.new(self, env)
      response = Response.new(request)

      if file = find_public_file(request.path_info[1..-1])
        response.stream_file(file)
        return response.to_a
      end

      handler = @router.match(request)

      catch(:abort_request) do
        dispatch_request(handler, request, response)
      end

      response.to_a
    end

    def dispatch_request(handler, request, response)
      start = Time.now

      return handle_not_found(request, response) unless handler

      handler.call(request, response)
    rescue StandardError, LoadError, SyntaxError => e
      handle_exception(e, request, response)
    ensure
      log_request(request, response, start, Time.now)
    end

    def log_request(request, response, start_time, end_time)
      message = "[#{request.remote_ip}] [#{request.request_method}] #{request.path_info} (#{response.status})"
      message << "\t#{request.params.inspect}" unless request.params.empty?

      if @logger
        logger.info message
      else
        $stdout.puts "[#{start_time.strftime('%m-%d-%Y @ %H:%M:%S')}] #{message}"
      end
    end

    def handle_not_found(request, response)
      response.flush
      response.status = 404

      response.layout = "layouts/exception" if Wheels::View.exists?("layouts/exception")

      if Wheels::View.exists?("exceptions/404.html.erb")
        response.render "exceptions/404.html.erb"
      else
        response.puts "The page you requested could not be found"
      end
    end

    def handle_exception(exception, request, response)
      response.flush
      response.status = 500

      trace = build_exception_trace(exception, request)

      if @logger
        logger.error trace
      else
        $stderr.puts trace
      end

      if environment == "development"
        response.puts(Rack::ShowExceptions.new(nil).pretty(request.env, exception))
      else
        response.layout = "layouts/exception" if Wheels::View.exists?("layouts/exception")

        if Wheels::View.exists?("exceptions/500.html.erb")
          response.render "exceptions/500.html.erb", :exception => exception
        else
          response.puts "We're sorry, but something went wrong."
        end
      end

    end

    def find_public_file(file)
      public_path = Pathname(self.class.respond_to?(:public_path) ? self.class.public_path : "public")
      path = public_path + file

      path.file? ? path : nil
    end

    private

    def build_exception_trace(exception, request)
      trace = ""
      trace << "="*80
      trace << "\n"
      trace << "== [ #{exception} @ #{Time.now} ] =="
      trace << "\n"
      trace << exception.backtrace.join("\n")
      trace << "\n"
      trace << "== [ Request ] =="
      trace << "\n"
      trace << request.env.to_yaml
      trace << "\n"
      trace << "="*80
      trace << "\n"
    end

  end
end