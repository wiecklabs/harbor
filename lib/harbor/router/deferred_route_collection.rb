require 'forwardable'

module Harbor
  class Router
    # TODO: Think about a better name for this... It handles 2 "collections" internally
    class DeferredRouteCollection
      attr_reader :static_routes, :wildcard_routes

      def initialize
        @wildcard_routes, @static_routes = [], []
      end

      def <<(route)
        routes = route.wildcard?? @wildcard_routes : @static_routes

        # TODO: Make sure this will scale
        index = routes.find_index { |r| r.normalized_tokens == route.normalized_tokens }
        routes.delete_at(index) if index
        routes << route
      end

      def clear
        @wildcard_routes.clear
        @static_routes.clear
      end
    end
  end
end
