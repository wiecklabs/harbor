module Harbor
  class Router
    class Tree
      attr_reader :root, :home

      def insert(tokens, action)
        if tokens.empty?
          @home = RouteNode.new(action)
        else
          (@root ||= RouteNode.new).insert(action, tokens)
        end
        self
      end

      def search(tokens)
        tokens.empty?? home : root.search(tokens)
      end
    end
  end
end
