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

    attr_accessor :router
    attr_reader :environment

    def initialize(router = self.class.routes, environment = ENV["ENVIRONMENT"])
      @router = router
      @environment = (environment || "development").to_s
    end

    def default_layout
      "layouts/application"
    end

    ##
    # Request entry point called by Rack. It creates a request and response
    # object based on the incoming request environment, checks for public
    # files, and dispatches the request.
    # 
    # It returns a rack response hash.
    ##
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

    ##
    # Request dispatch function, which handles 404's, exceptions,
    # and logs requests.
    ##
    def dispatch_request(handler, request, response)
      start = Time.now

      return handle_not_found(request, response) unless handler

      handler.call(request, response)
    rescue StandardError, LoadError, SyntaxError => e
      handle_exception(e, request, response)
    ensure
      log_request(request, response, start, Time.now)
    end

    ##
    # Logs requests and their params the configured request logger.
    # 
    # Format:
    # 
    #   #application      #time                   #duration   #ip              #method #uri      #status   #params
    #   [PhotoManagement] [04-02-2009 @ 14:22:40] [0.12s]     [64.134.226.23] [GET]    /products (200)     {"order" => "desc"}
    ##
    def log_request(request, response, start_time, end_time)

      case
      when response.status >= 500 then status = "\033[0;31m#{response.status}\033[0m"
      when response.status >= 400 then status = "\033[0;33m#{response.status}\033[0m"
      else status = "\033[0;32m#{response.status}\033[0m"
      end

      message = "[#{self.class}] [#{start_time.strftime('%m-%d-%Y @ %H:%M:%S')}] [#{"%2.2fs" % (end_time - start_time)}] [#{request.remote_ip}] [#{request.request_method}] #{request.path_info} (#{status})"
      message << "\t #{request.params.inspect}" unless request.params.empty?
      message << "\n"

      Logging::Logger['request'] << message if Logging::Logger['request'].info?
    end

    ##
    # Method used to nicely handle cases where no routes or public files
    # match the incoming request.
    # 
    # By default, it will render "The page you requested could not be found".
    # 
    # To use a custom 404 message, create a view "exceptions/404.html.erb", and
    # optionally create a view "layouts/exception.html.erb" to style it.
    ##
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

    ##
    # Method used to nicely handle uncaught exceptions.
    # 
    # Logs full error messages to the configured 'error' logger.
    # 
    # By default, it will render "We're sorry, but something went wrong."
    # 
    # To use a custom 500 message, create a view "exceptions/500.html.erb", and
    # optionally create a view "layouts/exception.html.erb" to style it.
    ##
    def handle_exception(exception, request, response)
      response.flush
      response.status = 500

      trace = build_exception_trace(exception, request)

      Logging::Logger['error'] << trace

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

    def find_public_file(file) #:nodoc:
      public_path = Pathname(self.class.respond_to?(:public_path) ? self.class.public_path : "public")
      path = public_path + file

      path.file? ? path : nil
    end

    private

    def build_exception_trace(exception, request)
      trace = ""
      trace << "="*80
      trace << "\n"
      trace << "== [ #{self.class}: #{exception} @ #{Time.now} ] =="
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