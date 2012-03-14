require_relative "route"
require_relative "route_node"
require_relative "wildcard_node"
require_relative "deferred_route"
require_relative "deferred_route_collection"

module Harbor
  class Router
    class HttpVerbRouter
      attr_accessor :root

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

        routes = deferred_routes.to_a
        deferred_routes.clear

        routes.sort!
        balanced_insert(routes)
      end

      def deferred_routes
        @deferred_routes ||= DeferredRouteCollection.new
      end

      def static_routes
        @static_routes ||= {}
      end

      private

      def insert_wildcard(tokens, action)
        (@root ||= RouteNode.new).insert(action, tokens, root_parent)
        self
      end

      def root_parent
        @root_parent ||= RootParent.new(self)
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

      # Acts as a "virtual" parent for root node, used for dealing with collisions
      class RootParent
        def initialize(tree)
          @tree = tree
        end
        def left
          @tree.root
        end
        def left=(node)
          @tree.root = node
        end
      end
    end
  end
end
