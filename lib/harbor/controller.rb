require_relative "router"
require_relative "controller/action"
require_relative "controller/normalized_path"
require_relative "router/helpers"

module Harbor
  class Controller
    
    def initialize(request, response)
      @request = request
      @response = response
    end

    attr_reader :request, :response

    private    
    extend Router::Helpers

    def self.route(method, path, handler)
      action_name = method_name_for_route(method, path)
      define_method(action_name, &handler)
      Router::instance.register(method, NormalizedPath.new(self, path), Action.new(self, action_name))
    end

    def self.method_name_for_route(http_method, path)
      return "GET__root__" if path == "/"
      parts = [ http_method.upcase ]

      Router::Route::expand(path).each do |part|
        parts << (part[0] == ?: ? "_#{part[1..-1]}" : part)
      end

      parts.join("_")
    end

  end
end
