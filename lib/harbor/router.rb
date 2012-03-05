require_relative "router/tree"
require_relative "router/route"
require_relative "router/wildcard_route"

module Harbor
  class Router

    def initialize
      clear!
    end

    attr_reader :methods

    def register(method, path, action)
      @methods[method].insert(Route::expand(path), action)
    end

    def match(method, path)
      @methods[method].search(Route::expand path)
    end

    def self.instance
      @instance ||= self.new
    end

    def clear!
      @methods = {
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
