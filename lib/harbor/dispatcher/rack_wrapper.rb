class Harbor
  class Dispatcher
    module RackWrapper
      def self.call(app, request_or_env, response)
        env = request_or_env.is_a?(Harbor::Request) ?
          request_or_env.env :
          request_or_env

        status, headers, buffer = app.call(env)
        response.status = status
        response.headers = headers
        response.buffer = buffer
      end
    end
  end
end
