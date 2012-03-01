require "set"
require_relative "router/route"

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
        "GET"     => Route.new,
        "POST"    => Route.new,
        "PUT"     => Route.new,
        "DELETE"  => Route.new,
        "HEAD"    => Route.new,
        "OPTIONS" => Route.new,
        "PATCH"   => Route.new
      }
    end
  end
end
