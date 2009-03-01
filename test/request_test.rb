require "helper"

class RequestTest < Test::Unit::TestCase
  def test_no_method_override_for_get
    assert_equal("GET", get("/").request_method)
    assert_equal("GET", get("/?_method=DELETE").request_method)
  end

  def test_method_override_for_post
    assert_equal("POST", post("/").request_method)
    assert_equal("POST", post("/?_request=delete").request_method)
    assert_equal("PUT", post("/", :input => "_method=put").request_method)
    assert_equal("DELETE", post("/", :input => "_method=delete").request_method)
  end

  def get(path, options = {})
    request(path, "GET", options)
  end

  def post(path, options = {})
    request(path, "POST", options)
  end

  def request(path, method, options)
    Wheels::Request.new(Class.new, Rack::MockRequest.env_for(path, options.merge(:method => method)))
  end

end