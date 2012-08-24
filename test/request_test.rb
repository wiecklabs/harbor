#!/usr/bin/env ruby

require_relative 'helper'

class RequestTest < MiniTest::Unit::TestCase
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

  def test_extracts_accept_types_preserving_quality_order
    request = get("/", { 'HTTP_ACCEPT' => 'text/plain; q=0.5, text/html, text/x-dvi; q=0.8, text/x-c, */*; q=0.1' })
    expected_accept = ['text/html', 'text/x-c', 'text/x-dvi', 'text/plain', '*/*']
    assert_equal expected_accept, request.accept
  end

  def test_returns_first_accepted_type_as_preferred
    request = get("/", { 'HTTP_ACCEPT' => 'text/x-c, */*; q=0.1' })

    text = 'text/x-c'
    js = 'application/javascript'

    assert_equal js, request.preferred_type([js])
    assert_equal text, request.preferred_type([js, text])
  end

  def test_extract_format_from_request_params
    request = get("/", { 'QUERY_STRING' => 'format=js' })
    assert_equal 'js', request.format
  end

  def test_returns_html_format_if_is_a_browser_request_and_not_ajax
    # Apparently this is what Safari will provide by default
    request = get("/", { 'HTTP_ACCEPT' => 'application/xml,application/xhtml+xml,text/html;q=0.9,text/plain;q=0.8,image/png,*/*;q=0.5' })
    assert_equal 'html', request.format
  end

  def test_returns_html_format_for_curl_like_requests
    request = get("/", { 'HTTP_ACCEPT' => '*/*' })
    assert_equal 'html', request.format
  end

  def test_identifies_preferred_format_if_ajax_request
    request = get("/", { 'HTTP_ACCEPT' => '*/*;q=0.5,application/json', "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest" })
    assert_equal 'json', request.format
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
