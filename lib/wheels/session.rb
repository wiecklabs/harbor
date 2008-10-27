module Wheels
  class Session
    def initialize(request)
      raise ArgumentError.new("+request+ must be a Wheels::Request") unless request.is_a?(Wheels::Request)
      @request = request
    end

    def [](key)
      @request.env["rack.session"][key]
    end

    def []=(key, value)
      @request.env["rack.session"][key] = value
    end

    def delete(key)
      @request.env["rack.session"].delete(key)
    end
  end
end