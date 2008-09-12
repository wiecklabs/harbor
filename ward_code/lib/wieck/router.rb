class Wieck
  class Router
    
    attr_accessor :routes
    
    # Constructor
    def initialize(env)
      @routes = []
    end
    
    # Dummy match method, just returns the first route
    def get_route()
      return @routes[0][:handler]
    end
    
    # Register a route
    def register(path, &handler)
      @routes.push({
        :path => path, 
        :handler => handler
      })
    end
    
  end
end