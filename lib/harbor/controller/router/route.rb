module Harbor
  class Controller
    class Router
      class Route
        def initialize(path, handler)
          @path = path
          @handler = handler
        end
      end
    end
  end
end