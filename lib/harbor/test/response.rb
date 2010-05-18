module Harbor
  module Test
    class Response < Harbor::Response

      attr_accessor :request

      ##
      # We redefine Harbor::Response.initialize(request) with an empty arg
      # variant for use with a container.
      ##
      def initialize
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
      
    end
  end
end