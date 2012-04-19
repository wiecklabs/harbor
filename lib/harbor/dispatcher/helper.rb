class Harbor
  class Dispatcher
    class Helper

      def self.instance
        @instance ||= self.new
      end

      %w{ get post put delete head options patch }.each do |verb|
        verb = verb.to_sym
        define_method verb do |path = '', params = {}|
          call(path, verb, params)
        end
      end

      protected

      def call(path, method, params)
        app.call(build_env(path, method, params))
      end

      def app
        @app ||= Harbor.new
      end

      def build_env(path, method, params)
        Rack::MockRequest.env_for(path, params.merge(:method => method.to_s.upcase))
      end
    end
  end
end

def harbor
  Harbor::Dispatcher::Helper::instance
end
