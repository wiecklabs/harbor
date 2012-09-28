module Harbor
  module Events
    class NotFoundEvent
      
      attr_reader :request, :response
      
      def initialize(request, response)
        @request = request
        @response = response
        @uri = request.uri
      end
      
      def uri
        @uri
      end
    end
  end
end