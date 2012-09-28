module Harbor
  module Events
    class DispatchRequestEvent
      
      attr_reader :request, :response, :start, :stop
      
      def initialize(request, response)
        @request = request
        @response = response
        @start = Time::now
        @stop = nil
      end
      
      def complete!
        @stop = Time::now
        self
      end
      
      def duration
        @stop - @start
      end
    end
  end
end