require "set"
require "harbor/controller/router"

module Harbor
  class Controller
    
    def initialize(request, response)
      @request = request
      @response = response
    end
  
    attr_reader :request, :response
    
    private
    def self.get(path = "", &handler)
      route("GET", path, handler)
    end
    
    def self.post(path = "", &handler)
      route("POST", path, handler)
    end
    
    def self.put(path = "", &handler)
      route("PUT", path, handler)
    end
        
    def self.delete(path = "", &handler)
      route("DELETE", path, handler)
    end
    
    def self.head(path = "", &handler)
      route("HEAD", path, handler)
    end
    
    def self.options(path = "", &handler)
      route("OPTIONS", path, handler)
    end
    
    def self.patch(path = "", &handler)
      route("PATCH", path, handler)
    end
    
    def self.route(method, path, handler)
      action_name = method_name_for_route(method, path)
      define_method(action_name, &handler)
      Router::instance.register(method, absolute_route_path(self, path), self, action_name)
    end
    
    def self.method_name_for_route(http_method, path)
      
      parts = [ http_method.upcase ]
      
      Router::Route::expand(path).each do |part|
        parts << (part[0] == ?: ? "_#{part[1..-1]}" : part)
      end
      
      parts.join("_")
    end
    
    def self.absolute_route_path(controller, route)
      if route[0] == ?/
        route[1..-1]
      else
        parts = [ ]
        klass = Kernel
        controller.name.split("::").each do |part|
          klass = klass.const_get(part)
          if !(klass < Harbor::Application) && part != "Controllers"
            parts << part.underscore
          end
        end
        (parts << route).join("/")
      end
    end
  end
end