module Harbor
  class Router
    class DeferredRoute
      include Comparable

      attr_reader :tokens, :action

      def initialize(tokens, action)
        @tokens, @action = tokens, action
      end

      def normalized_tokens
        @normalized_tokens ||= @tokens.map do |token|
          token[0] == Route::WILDCARD_CHAR ?
            Route::WILDCARD_FRAGMENT :
            token
        end
      end

      def <=>(other)
        self.normalized_tokens <=> other.normalized_tokens
      end
    end
  end
end
