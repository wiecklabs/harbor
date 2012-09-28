require "forwardable"

class Harbor
  class Router
    # Handles deferred wildcard routes
    class DeferredRouteSet
      extend Forwardable
      def_delegators :@routes, :size, :empty?

      def initialize
        @routes = {}
      end

      def <<(route)
        @routes[route.normalized_tokens] = route
      end

      def clear
        @routes.clear
      end

      def to_a
        @routes.values
      end
    end
  end
end
