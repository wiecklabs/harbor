require "set"
require "controller/router/route"

module Harbor
  class Controller
    class Router
      def initialize
        @routes ||= Set.new
      end
      
      def register(path, handler)
        @routes << Route.new(route, handler)
      end
      
      def match(path)
        tokens = *path.split(/(\/|\;|\:)/)
        tokens.each 
      end
    end
  end
end