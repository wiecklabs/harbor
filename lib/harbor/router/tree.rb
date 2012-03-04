module Harbor
  class Router
    class Tree
      attr_reader :root, :home

      def insert(tokens, action)
        if tokens.empty?
          @home = RouteNode.new(action)
        elsif @root
          @root.insert(action, tokens)
        else
          @root = RouteNode.new(action, tokens)
        end
        self
      end

      def search(tokens)
        if tokens.empty?
          home
        else
          root.search(tokens)
        end
      end
    end
  end
end
