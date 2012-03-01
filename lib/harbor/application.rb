require "jruby-rack"

require "yaml"

require_relative "events"
require_relative "request"
require_relative "response"
require_relative "block_io"
require_relative "events/dispatch_request_event"
require_relative "events/not_found_event"
require_relative "events/application_exception_event"
require_relative "events/session_created_event_context"
require_relative "event_context"
require_relative "messages"

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

    def router
      @router ||= self.class::routes(config)
    end

    def initialize(services = nil, *args)
      @router = args.first if args.first.is_a?(Harbor::Router)
    end

    ##
    # Request entry point called by Rack. It creates a request and response
    # object based on the incoming request environment, checks for public
    # files, and dispatches the request.
    #
    # It returns a rack response hash.
    ##
    def call(env)
      request = Request.new(self, env)
      response = Response.new(request)

      catch(:abort_request) do
        handler = router.match(request)
        dispatch_request(handler, request, response)
      end

      response.to_a
    end

    def match(request)
      router.match(request)
    end

    ##
    # Request dispatch function, which handles 404's, exceptions,
    # and logs requests.
    ##
    def dispatch_request(handler, request, response)
      dispatch_request_event = Events::DispatchRequestEvent.new(request, response)
      raise_event(:request_dispatch, dispatch_request_event)

      return handle_not_found(request, response) unless handler

      handler.call(request, response)
    rescue StandardError, LoadError, SyntaxError => e
      handle_exception(e, request, response)
    ensure
      raise_event(:request_complete, dispatch_request_event.complete!)
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

      raise_event(:not_found, Events::NotFoundEvent.new(request, response))
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

      if config.development?
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

      raise_event(:exception, ApplicationExceptionEvent.new(request, response, exception))

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

  end
end
