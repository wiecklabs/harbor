require "pathname"
require Pathname(__FILE__).dirname + "helper"

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

  def test_params_fetch
    request = get("/", { 'QUERY_STRING' => 'fruit=apple&preperation=&servings=' })

    assert_equal('apple', request.fetch('fruit'))
    assert_equal(nil, request.fetch('preperation'))
    assert_equal(nil, request.fetch('servings'))

    assert_equal('apple', request.fetch('fruit', 'orange'))
    assert_equal('diced', request.fetch('preperation', 'diced'))
    assert_equal(4, request.fetch('servings', 4))
  end

  def test_get_params_raises_on_bad_input
    request = get("/", { 'QUERY_STRING' => 'somekey=%%' })
    assert_raise(Harbor::BadRequestParametersError) { request.params }
  end

  def test_post_params_raises_on_bad_input
    request = post("/", { :input => 'somekey=%a' })
    assert_raise(Harbor::BadRequestParametersError) { request.params }
  end

  def get(path, options = {})
    request(path, "GET", options)
  end

  def post(path, options = {})
    request(path, "POST", options)
  end

  def request(path, method, options)
    Harbor::Request.new(Class.new, Rack::MockRequest.env_for(path, options.merge(:method => method)))
  end

end