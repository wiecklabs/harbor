module Wheels
  ##
  # Middleware for storing data in a cookie using JSON, for later access
  # via javascript.
  # 
  #   use Wheels::JsonCookies, "key_to_serialize", "other_key"
  ##
  class JsonCookies
    def initialize(app, keys = [])
      @app = app
      @keys = keys
    end

    def call(env)
      read_cookies(env)
      status, headers, body = @app.call(env)
      write_cookies(env, status, headers, body)
    end

    private

    def read_cookies(env)
      request = Rack::Request.new(env)
      (request.cookies.keys & @keys).each do |key|
        env[key] = JSON.parse(request.cookies[key]) rescue nil
      end
    end

    def write_cookies(env, status, headers, body)
      response = Rack::Response.new(body, status, headers)
      @keys.each do |key|
        response.set_cookie(key, :value => env[key].to_json, :path => "/")
      end
      response.to_a
    end
  end
end