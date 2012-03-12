module Harbor
  class Router
    class Route
      WILDCARD_FRAGMENT = '*'
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
    end
  end
end
