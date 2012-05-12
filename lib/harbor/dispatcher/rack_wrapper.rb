class Harbor
  class Dispatcher
    class RackWrapper
      def initialize(app)
        @app = app
      end

      def call(request, response)
        status, headers, buffer = @app.call(request.env)
        response.status = status
        response.headers = headers
        response.buffer = buffer
      end
    end
  end
end
