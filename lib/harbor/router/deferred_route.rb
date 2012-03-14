module Harbor
  class Router
    class DeferredRoute
      include Comparable

      attr_reader :tokens, :action, :normalized_tokens

      def initialize(tokens, action)
        @tokens, @action = tokens, action
        normalize_tokens!
      end

      def <=>(other)
        self.normalized_tokens <=> other.normalized_tokens
      end

      private

      def normalize_tokens!
        @normalized_tokens ||= @tokens.map do |token|
          RouteNode.fragment_from_token(token)
        end
      end
    end
  end
end
