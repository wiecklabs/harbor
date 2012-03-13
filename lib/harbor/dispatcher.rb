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
      catch(:abort_request) do
        request_path = (request.path_info[-1] == ?/) ? request.path_info[0..-2] : request.path_info
        if route = router.match(request.request_method, request_path)
          request.params.merge!(extract_params_from_tokens(route.tokens, request_path))
          route.action.call(request, response)
        end
      end
    end

    private

    def extract_params_from_tokens(tokens, request_path)
      pairs = Router::Route.expand(request_path).zip(tokens)
      pairs.each_with_object({}) do |pair, params|
        value, token = pair
        params[token[1..-1]] = value if token && Router::Route.wildcard_token?(token)
      end
    end
  end
end
