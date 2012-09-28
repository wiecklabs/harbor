class Harbor
  module Test
    class Request < Harbor::Request

      attr_accessor :session, :env, :params

      def params
        @params ||= {}
      end

      ##
      # Rack::Response defines self.new(env, *args), which means we can't initialize
      # a new request via a container without replacing this method.
      ##
      def self.new(*args)
        super(nil, {})
      end

      def session
        session = @session || Session.new
        session.request = self
        session
      end

      def session=(session)
        @session = Session.new(session)
        @session.request = self
        @session
      end

      def request_method=(method)
        @env['REQUEST_METHOD'] = method.to_s.upcase
      end
    end
  end
end
