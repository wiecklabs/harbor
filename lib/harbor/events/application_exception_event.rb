module Harbor
  module Events
    class ApplicationExceptionEvent
      
      attr_reader :request, :response, :exception
      
      def initialize(request, response, exception)
        @request = request
        @response = response
        @exception = exception
        @occurred = Time::now
      end
      
      def trace
        <<-EOS
================================================================================
== [ ApplicationExceptionEvent: #{@exception} @ #{@occurred} ] ==

#{@exception.backtrace.join("\n")}

== [ Request ] ==

#{@request.env.to_yaml}

================================================================================
EOS
      end
    end
  end
end