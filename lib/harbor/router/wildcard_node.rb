module Harbor
  class Router
    # Used to replace a "simple" node with n-way search tree
    class WildcardNode
      attr_accessor :wildcard_tree

      def initialize(node = nil)
        @trees = {}
        return unless node

        if node.wildcard?
          @wildcard_tree = node
        elsif node.fragment
          @trees[node.fragment] = node
        end
      end

      def search(tokens)
        part = tokens.first

        exact_result = if (tree = trees[part])
          # The dup is required as the search method will consume tokens
          tree.search(tokens.dup)
        end
        return exact_result if exact_result

        # An exact match could be found? Lets give one last shot and try to match
        # wildcard routes ;)
        @wildcard_tree.search(tokens) if @wildcard_tree
      end

      def find_or_create_node!(tokens, index = 0, parent = nil)
        part = tokens[index]
        if Route.wildcard_token?(part)
          (@wildcard_tree ||= RouteNode.new).find_or_create_node!(tokens, index, parent)
        else
          (trees[part] ||= RouteNode.new).find_or_create_node!(tokens, index, parent)
        end
      end

      def trees
        @trees ||= {}
      end
    end
  end
end
