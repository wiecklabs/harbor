require_relative "route"
require_relative "route_node"
require_relative "deferred_route"
require_relative "deferred_route_collection"
require_relative "wildcard_route"

module Harbor
  class Router
    class HttpVerbRouter
      attr_reader :root, :home

      def register(tokens, action)
        deferred_routes << DeferredRoute.new(tokens, action)
        self
      end

      def insert!(tokens, action)
        if tokens.empty?
          @home = Route.new(action)
        elsif wildcard?(tokens)
          (@root ||= RouteNode.new).insert(action, tokens)
        else
          static_routes.delete(tokens.join('/'))
          static_routes[tokens.join('/')] = Route.new(action)
        end
        self
      end

      def search(tokens)
        build! unless @built

        result = if tokens.empty?
          home
        elsif route = static_routes[tokens.join('/')]
          route
        elsif root
          root.search(tokens)
        end
        result.action if result
      end

      def build!
        return @built = true if @built || (deferred_routes.wildcard_routes.empty? && deferred_routes.static_routes.empty?)

        deferred_routes.wildcard_routes.sort!
        balanced_insert(deferred_routes.wildcard_routes)

        deferred_routes.static_routes.each do |route|
          insert!(route.tokens, route.action)
        end

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

      def wildcard?(tokens)
        tokens.detect{|token| token[0] == Route::WILDCARD_CHAR }
      end

      def balanced_insert(array)
        return if array.empty?

        middle = (array.size / 2)
        middle_element = array.delete_at(middle)
        left = array.slice!(0, middle)
        right = array

        insert!(middle_element.tokens, middle_element.action)

        balanced_insert(left) unless left.empty?
        balanced_insert(right) unless right.empty?
      end
    end
  end
end
