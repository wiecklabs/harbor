require_relative "route"
require_relative "route_node"
require_relative "wildcard_node"
require_relative "deferred_route"
require_relative "deferred_route_collection"

module Harbor
  class Router
    class HttpVerbRouter
      attr_reader :root, :home

      def register(tokens, action)
        if wildcard?(tokens)
          deferred_routes << DeferredRoute.new(tokens, action)
        else
          static_routes[tokens.join('/')] = Route.new(action, tokens)
        end
        self
      end

      def search(tokens)
        build!

        if route = static_routes[tokens.join('/')]
          route
        elsif root
          root.search(tokens)
        end
      end

      def build!
        return if deferred_routes.empty?

        deferred_routes.sort!
        balanced_insert(deferred_routes)

        deferred_routes.clear
        @built = true
      end

      def deferred_routes
        @deferred_routes ||= DeferredRouteCollection.new
      end

      def static_routes
        @static_routes ||= {}
      end

      private

      def insert_wildcard(tokens, action)
        (@root ||= RouteNode.new).insert(action, tokens)
        self
      end

      def wildcard?(tokens)
        tokens.detect{|token| Route.wildcard_token?(token) }
      end

      def balanced_insert(array)
        return if array.empty?

        middle = (array.size / 2)
        middle_element = array.delete_at(middle)
        left = array.slice!(0, middle)
        right = array

        insert_wildcard(middle_element.tokens, middle_element.action)

        balanced_insert(left) unless left.empty?
        balanced_insert(right) unless right.empty?
      end
    end
  end
end
