require "set"
require "harbor/controller/router"

module Harbor
  class Controller
    
    include Models
    
    Photo.get(id)
    
    def self.routes
      @routes ||= {}
    end
    
    def initialize(request, response)
      @request = request
      @response = response
    end
  
    attr_reader :request, :response
    
    def self.get(path, &handler)
      (routes["GET"] ||= Router.new).register(path, handler)
    end
    
    def self.put(path, &handler)
      (routes["PUT"] ||= Router.new).register(path, handler)
    end
    
    def self.post(path, &handler)
      (routes["POST"] ||= Router.new).register(path, handler)
    end
    
    def self.put(path, &handler)
      (routes["PUT"] ||= Router.new).register(path, handler)
    end
    
    def self.delete(path, &handler)
      (routes["DELETE"] ||= Router.new).register(path, handler)
    end
    
    def self.head(path, &handler)
      (routes["HEAD"] ||= Router.new).register(path, handler)
    end
    
    private
    def self.method_name_for_route(http_method, route)
      
      parts = [ http_method.upcase ]
      
      route.split(Harbor::Controller::Router::PATH_SEPARATOR).each do |part|
        parts << (part[0] == ?: ? "__#{part}__" : part)
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