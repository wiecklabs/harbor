module Harbor
  class Controller
    class Router
      class Route
        def initialize(path, handler)
          @path = path
          @handler = handler
          
          @tokens = path.split(Harbor::Controller::Router::PATH_SEPARATOR)
        end
        
        attr_reader :tokens
        
        def to_proc
          @handler
        end
      end
    end
  end
end