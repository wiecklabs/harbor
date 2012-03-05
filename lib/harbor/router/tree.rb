module Harbor
  class Router
    class Tree
      attr_reader :root, :home

      def insert(tokens, action)
        if tokens.empty?
          @home = Route.new(action)
        else
          (@root ||= Route.new).insert(action, tokens)
        end
        self
      end

      def search(tokens)
        result = tokens.empty?? home : root.search(tokens)
				result.action if result
      end
    end
  end
end
