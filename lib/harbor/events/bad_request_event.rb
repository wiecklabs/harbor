module Harbor
  module Events
    class BadRequestEvent

      attr_reader :request, :response, :bad_request_exception

      def initialize(request, response, bad_request_exception)
        @request = request
        @response = response
        @bad_request_exception = bad_request_exception
        @occurred = Time::now
      end

      def trace
        exception_to_log = @bad_request_exception.inner_exception || @bad_request_exception

        <<-EOS
#{exception_to_log}

#{exception_to_log.backtrace.join("\n")}

URI: #{@request.env['REQUEST_URI']}

#{@request.env.to_yaml}

^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
EOS
      end
    end
  end
end
