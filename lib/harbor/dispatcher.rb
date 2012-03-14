module Harbor
  class Dispatcher
    def self.instance
      @instance ||= self.new
    end

    def router
      @router ||= Harbor::Router::instance
    end

    def initialize(router = nil)
      @router = router
    end

    def dispatch!(request, response)
      fragments = Router::Route.expand(request.path_info)

      if route = router.match(request.request_method, fragments)
        abort_unless_action!(response, route)

        request.params.merge!(extract_params_from_tokens(route.tokens, fragments))

        route.action.call(request, response)
      end
    end

    private

    def abort_unless_action!(response, route)
      return if route.action

      response.status = 404
      throw(:abort_request)
    end

    def extract_params_from_tokens(tokens, fragments)
      pairs = fragments.zip(tokens)
      pairs.each_with_object({}) do |pair, params|
        value, token = pair
        params[token[1..-1]] = value if token && Router::Route.wildcard_token?(token)
      end
    end
  end
end
