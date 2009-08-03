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
      end

    end
  end
end