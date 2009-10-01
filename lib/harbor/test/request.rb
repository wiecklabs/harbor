module Harbor
  module Test
    class Request < Harbor::Request

      attr_accessor :session, :env

      ##
      # Rack::Response defines self.new(env, *args), which means we can't initialize
      # a new request via a container without replacing this method.
      ##
      def self.new(*args)
        super(nil, {})
      end

      def session
        @session || Session.new
      end

      def session=(session)
        @session = Session.new(session)
      end
    end
  end
end