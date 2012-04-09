class Harbor
  class Dispatcher
    ##
    # Holds a list of applications that _might_ handle a request that was not
    # handled by app's controllers. Currently its only used for serving static
    # assets during development but in the future we might add a thin wrapper
    # to support cascading Rack apps.
    ##
    class Cascade
      def initialize
        @apps = []
      end

      def match(request)
        @apps.find{ |app| app.match(request) }
      end

      def register(app)
        unless app.respond_to?(:match) && app.respond_to?(:call)
          raise ArgumentError.new "#{app} should respond to match and call to be cascaded"
        end
        @apps << app unless @apps.include? app
      end
      alias << register

      def unregister(app)
        @apps.delete(app)
      end

      def apps
        @apps.freeze
      end
    end
  end
end
