module Harbor
  class Router
    # TODO: Add inspect information to distinguish from "normal" routes
    module WildcardRouteNode
      def search
        raise 'Not working yet'
      end

      def insert(action, tokens)
        raise 'Not working yet'
      end

      def trees
        @trees ||= {}
      end
    end
  end
end
