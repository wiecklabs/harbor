require 'lib/wieck/router'
require 'lib/wieck/request'
require 'lib/wieck/response'
require 'lib/wieck/controller'

class Wieck
  class App
    
    attr_accessor :router, :response, :request
            
    # Init Application Here
    def call(env)
      @router   = Wieck::Router.new(env)
      @request  = Wieck::Request.new(env)
      @response = Wieck::Response.new(env)
      
      # This would be defined somewhere else, like an external file
      @router.register "/" do |request, response|
        require 'app/controllers/default.rb'
        Wieck::Controllers::Default.new(request, response).index
      end
      
      route = @router.get_route()
      #@response.write(route.call(@request, @response))
      
      route.call(@request, @response)
      
      if (!@response.rendered)
        @response.render_nothing
      end
      
      return @response.output
    end
    
    # Register route to default router
    def register_route(path, &handler)
      @router.register(path, handler)
    end
    
  end
end