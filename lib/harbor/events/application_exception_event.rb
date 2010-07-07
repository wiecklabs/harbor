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
#{@exception} (#{@exception.backtrace.first})

#{@exception.backtrace.join("\n")}

== [ Request ] ==

#{@request.env.to_yaml}

================================================================================
EOS
      end
    end
  end
end
