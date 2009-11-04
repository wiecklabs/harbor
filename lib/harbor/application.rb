gem "rack", "~> 1.0.0"
require "rack"

require "yaml"

require Pathname(__FILE__).dirname + "request"
require Pathname(__FILE__).dirname + "response"
require Pathname(__FILE__).dirname + "block_io"
require Pathname(__FILE__).dirname + "zipped_io"
require Pathname(__FILE__).dirname + "events"
require Pathname(__FILE__).dirname + "messages"

module Harbor
  class Application

    include Harbor::Events
    
    ##
    # Routes are defined in this method. Note that Harbor does not define any default routes,
    # so you must reimplement this method in your application.
    ##
    def self.routes(services)
      raise NotImplementedError.new("Your application must redefine #{self}::routes.")
    end

    attr_reader :router, :environment, :services

    def initialize(services, *args)
      unless services.is_a?(Harbor::Container)
        raise ArgumentError.new("Harbor::Application#services must be a Harbor::Container")
      end

      @services = services

      @router = (!args.empty? && !args[0].is_a?(String) && args[0].respond_to?(:match)) ? args.shift : self.class.routes(@services)
      @environment = args.last || "development"
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

      catch(:abort_request) do
        if file = find_public_file(request.path_info[1..-1])
          response.cache(nil, ::File.mtime(file), 86400) do
            response.stream_file(file)
          end

          return response.to_a
        end

        handler = @router.match(request)

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
      raise_event(:request_complete, request, response, start, Time.now)
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

      response.layout = "layouts/exception" if Harbor::View.exists?("layouts/exception")

      if Harbor::View.exists?("exceptions/404.html.erb")
        response.render "exceptions/404.html.erb"
      else
        response.puts "The page you requested could not be found"
      end

      raise_event(:not_found, request, response)
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

      if environment == "development"
        response.content_type = "text/html"
        response.puts(Rack::ShowExceptions.new(nil).pretty(request.env, exception))
      else
        response.layout = "layouts/exception" if Harbor::View.exists?("layouts/exception")

        if Harbor::View.exists?("exceptions/500.html.erb")
          response.render "exceptions/500.html.erb", :exception => exception
        else
          response.puts "We're sorry, but something went wrong."
        end
      end

      raise_event(:exception, exception, request, response, trace)

      nil
    end

    def find_public_file(file) #:nodoc:
      public_path = Pathname(self.class.respond_to?(:public_path) ? self.class.public_path : "public")
      path = public_path + file

      path.file? ? path : nil
    end

    def default_layout
      warn "Harbor::Application#default_layout has been deprecated. See Harbor::Layouts."
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
