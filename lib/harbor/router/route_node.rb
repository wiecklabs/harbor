module Harbor
  class Router
    class RouteNode
      MATCH             = 0
      RIGHT             = 1
      LEFT              = -1
      WILDCARD_FRAGMENT = '*'
      WILDCARD_CHAR     = ?:

      attr_reader :fragment, :tokens
      attr_accessor :action, :left, :right, :match

      # Inserts or updates tree nodes
      #
      # @return [ RouteNode ] The inserted node
      def insert(action, tokens)
        (leaf = find_or_create_node!(tokens)).action = action
        leaf
      end

      # Finds or create nodes for provided tokens, if a node is not found for a
      # token, a "blank" node will be created and the search will continue.
      #
      # @return [ RouteNode ] The node for a set of tokens
      def find_or_create_node!(tokens, index = 0)
        part = tokens[index]
        last_token = index == tokens.size - 1

        # Non wildcard routes should take precedence
        if wildcard? && part[0] != WILDCARD_CHAR
          replace!(tokens, index)
        end

        if @fragment.nil?
          @fragment = fragment_from_token(part)
          # Removes "extra" tokens
          @tokens = tokens[0..index]
        end

        # Ensures "virtual" wildcard nodes have the right tokens set so
        # that we can map parameters back to route handlers
        @tokens = tokens[0..index] if wildcard? && last_token

        direction = wildcard?? MATCH : part <=> @fragment

        # If it is a match and there are no more fragments to consume
        return self if last_token && direction == MATCH

        case direction
        when MATCH
          (@match ||= RouteNode.new).find_or_create_node!(tokens, index + 1)
        when LEFT
          (@left ||= RouteNode.new).find_or_create_node!(tokens, index)
        when RIGHT
          (@right ||= RouteNode.new).find_or_create_node!(tokens, index)
        end
      end

      def wildcard?
        @fragment == WILDCARD_FRAGMENT
      end

      def fragment_from_token(token)
        (token[0] == WILDCARD_CHAR) ? WILDCARD_FRAGMENT : token
      end

      def replace!(tokens, index)
        @left = RouteNode.new.insert(@action, @tokens)
        @right = nil
        @action = nil
        @tokens = nil
        @fragment = nil
      end
    end
  end
end
