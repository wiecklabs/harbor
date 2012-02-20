module Harbor
  class Controller
    class Router
      class Route
        def initialize(path, controller, action_name)
          @path = path
          @controller = controller
          @action_name = action_name
          
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