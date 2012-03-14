module Harbor
  class Router
    class Route
      WILDCARD_CHAR     = ?:
      PATH_SEPARATOR    = /[\/;]/

      def self.expand(path)
        path.split(PATH_SEPARATOR).reject { |part| part.empty? }
      end

      attr_accessor :action, :tokens

      def initialize(action = nil, tokens = nil)
        @action = action
        @tokens = tokens
      end

      def self.wildcard_token?(token)
        token[0] == Route::WILDCARD_CHAR
      end
    end
  end
end
