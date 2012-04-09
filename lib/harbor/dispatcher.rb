require_relative 'dispatcher/cascade'

class Harbor
  class Dispatcher

    include Harbor::Events

    def self.instance
      @instance ||= self.new
    end

    def router
      @router ||= Harbor::Router::instance
    end

    def cascade
      @cascade ||= Cascade.new
    end

    def initialize(router = nil)
      @router = router
    end

    def dispatch!(request, response)
      dispatch_request_event = Events::DispatchRequestEvent.new(request, response)

      fragments = Router::Route.expand(request.path_info)
      route = router.match(request.request_method, fragments)
      if route && route.action
        request.params.merge!(extract_params_from_tokens(route.tokens, fragments))

        catch(:halt) do
          raise_event(:request_dispatch, dispatch_request_event)
          route.action.call(request, response)
        end
      elsif app = cascade.match(request)
        catch(:halt) do
          app.call(request, response)
        end
      else
        handle_not_found(request, response)
      end
    rescue Exception => e
      handle_exception(e, request, response)
    ensure
      raise_event(:request_complete, dispatch_request_event.complete!)
    end

    private

    def extract_params_from_tokens(tokens, fragments)
      pairs = fragments.zip(tokens)
      pairs.each_with_object({}) do |pair, params|
        value, token = pair
        params[token[1..-1]] = value if token && Router::Route.wildcard_token?(token)
      end
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

      raise_event(:exception, Events::ServerErrorEvent.new(request, response, exception))
    end
  end
end
