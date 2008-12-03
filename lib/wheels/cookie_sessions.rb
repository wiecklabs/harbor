module Wheels
  class CookieSessions < Rack::Session::Cookie

    private

    def commit_session(env, status, headers, body)
      # Commit session variables
      status, headers, body = super

      request = Rack::Request.new(env)
      response = Rack::Response.new(body, status, headers)

      if request.cookies["_session_id"]
        session_id = request.cookies["_session_id"]
      else
        session_id = `uuidgen`.chomp
      end

      options = env["rack.session.options"]
      cookie = Hash.new
      cookie[:value] = session_id
      cookie[:expires] = Time.now + options[:expire_after] unless options[:expire_after].nil?

      response.set_cookie("_session_id", cookie.merge(options))
      response.to_a
    end

  end
end