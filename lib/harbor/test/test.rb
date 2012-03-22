class Harbor
  module Test

    require Pathname(__FILE__).dirname + "request"
    require Pathname(__FILE__).dirname + "response"
    require Pathname(__FILE__).dirname + "session"
    require Pathname(__FILE__).dirname + "mailer"

    def assert_redirect(response)
      assert_equal 303, response.status, "Expected Response#status 303 but was #{response.status}"
    end

    def assert_success(response)
      assert_equal 200, response.status, "Expected Response#status 200 but was #{response.status}"
    end

    def assert_unauthorized(response)
      assert_equal 401, response.status, "Expected Response#status 401 but was #{response.status}"
    end
    
    def assert_cookie_deleted(response, key)
      assert(response.deleted_cookies.include?(key), "Expected Response Cookie #{key} to have been deleted, but it wasn't")
    end

    def assert_cookie_set(response, key, value)
      assert_equal(value, response.set_cookies[key] && response.set_cookies[key][:value], "Expected Response Header Set-Cookie to set value for #{key} to #{value}, but it was set to: #{response.set_cookies[key]}")
    end

  end
end