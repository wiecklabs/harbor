require "set"
require "controller/router"

module Harbor
  class Controller
  
    def self.inherited(klass)
      
    end
    
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
  end
end