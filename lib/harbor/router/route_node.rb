module Harbor
  class Router
    class RouteNode
      attr_reader :action, :fragment

      def initialize(action, tokens = [])
        @action = action
        @fragment = tokens.shift
      end
    end
  end
end
