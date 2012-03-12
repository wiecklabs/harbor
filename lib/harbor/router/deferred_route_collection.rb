require 'forwardable'

module Harbor
  class Router
    # Handles deferred wildcard routes
    class DeferredRouteCollection
      extend Forwardable

      # TODO: Do we really need all of this or can we just provide a #to_a / #to_ary ?
      def_delegators :@routes, :sort!, :empty?, :size, :delete_at, :slice!,
                               :first, :clear

      attr_reader :routes

      def initialize
        @routes = []
      end

      def <<(route)
        # TODO: Make sure this will scale
        index = routes.find_index { |r| r.normalized_tokens == route.normalized_tokens }
        routes.delete_at(index) if index
        routes << route
      end
    end
  end
end
