class Harbor
  module Test
    class Response < Harbor::Response

      attr_accessor :request, :context, :deleted_cookies, :set_cookies

      ##
      # We redefine Harbor::Response.initialize(request) with an empty arg
      # variant for use with a container.
      ##
      def initialize
        self.context = []
        super(nil)

        @deleted_cookies = []
        @set_cookies = {}
      end
      
      def delete_cookie(key, value={})
        super(key, value)
        @deleted_cookies << key
      end
      
      def set_cookie(key, value)
        super(key, value)
        @set_cookies[key] = value
      end

      ##
      # Gives us access to the context, so instance variables can be assessed
      ##
      def render(view, context = {})
        self.context << context
        super(view, context)
      end

      ##
      # Cycle handles multi-render actions
      ##
      def render_context(cycle = 0)
        context[cycle]
      end

    end
  end
end