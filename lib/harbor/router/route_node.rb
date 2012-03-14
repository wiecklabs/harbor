module Harbor
  class Router
    # A Ternary Search tree implementation that can be extended to a n-way search
    # tree at insertion time.
    class RouteNode < Route
      MATCH             = 0
      RIGHT             = 1
      LEFT              = -1
      WILDCARD_FRAGMENT = '*'

      attr_reader :fragment
      attr_accessor :left, :right, :match

      def initialize(action = nil, tokens = nil, fragment = nil)
        super(action, tokens)
        @fragment = fragment
      end

      def self.wildcard_fragment?(fragment)
        fragment == WILDCARD_FRAGMENT
      end

      def self.fragment_from_token(token)
        Route.wildcard_token?(token) ? WILDCARD_FRAGMENT : token
      end

      def wildcard?
        self.class.wildcard_fragment?(@fragment)
      end

      # Basic ternary search tree algorithm
      def search(tokens, current_token = nil)
        current_token = tokens.shift unless current_token

        if current_token == @fragment || wildcard?
          return self if tokens.empty?
          return @match.search(tokens) if @match
        end

        return @left.search(tokens, current_token) if @left && current_token < @fragment
        return @right.search(tokens, current_token) if @right && current_token > @fragment
      end

      # Inserts or updates tree nodes
      #
      # @return [ Route ] The inserted node
      def insert(action, tokens, parent = nil)
        # parent = nil is just to simplify testing, we should always
        # call the method with parent node
        leaf = find_or_create_node!(tokens, 0, parent)
        leaf.action = action
        leaf.tokens = tokens
        leaf
      end

      # Finds or create nodes for provided tokens, if a node is not found for a
      # token, a "blank" node will be created and the search will continue.
      #
      # @return [ Route ] The node for a set of tokens
      def find_or_create_node!(tokens, index = 0, parent = nil)
        part = tokens[index]

        # This will extend the current node with "complex wildcard behavior" /
        # n-way search tree
        return replace!(tokens, index, parent) if should_replace?(part)

        if @fragment.nil?
          @fragment = self.class.fragment_from_token(part)
        end

        # Wildcard routes should always be considered matches
        direction = wildcard?? MATCH : part <=> @fragment

        is_last_token = index == tokens.size - 1
        # If it is a match and there are no more fragments to consume
        return self if is_last_token && direction == MATCH

        case direction
        when MATCH
          (@match ||= RouteNode.new).find_or_create_node!(tokens, index + 1, self)
        when LEFT
          (@left ||= RouteNode.new).find_or_create_node!(tokens, index, self)
        when RIGHT
          (@right ||= RouteNode.new).find_or_create_node!(tokens, index, self)
        end
      end

      def should_replace?(part)
        incoming_wildcard = Route.wildcard_token?(part)
        # On a wildcard node with an incoming "non-wildcard" node
        (wildcard? && !incoming_wildcard) ||
          # ... or on a "non-wildcard" node with an incoming wildcard node
          !@fragment.nil? && !wildcard? && incoming_wildcard
      end

      def replace!(tokens, index, parent)
        extend WildcardNode
        find_or_create_node!(tokens, index, parent)
      end

      def assign_from(other_node)
        @left     = other_node.left
        @right    = other_node.right
        @action   = other_node.action
        @tokens   = other_node.tokens
        @fragment = other_node.fragment
        @match    = other_node.match
        self
      end

      def reset!
        @left     = nil
        @right    = nil
        @match    = nil
        @action   = nil
        @tokens   = nil
        @fragment = nil
      end
    end
  end
end
