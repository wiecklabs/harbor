require_relative "router/tree"
require_relative "router/route"
require_relative "router/deferred_route"
require_relative "router/deferred_route_collection"
require_relative "router/wildcard_route"

module Harbor
  class Router

    def initialize
      clear!
    end

    attr_reader :verbs

    def register(method, path, action)
      @verbs[method].register(Route::expand(path), action)
    end

    def match(method, path)
      @verbs[method].search(Route::expand path)
    end

    def self.instance
      @instance ||= self.new
    end

    def clear!
      @verbs = {
        "GET"     => Tree.new,
        "POST"    => Tree.new,
        "PUT"     => Tree.new,
        "DELETE"  => Tree.new,
        "HEAD"    => Tree.new,
        "OPTIONS" => Tree.new,
        "PATCH"   => Tree.new
      }
    end
  end
end
