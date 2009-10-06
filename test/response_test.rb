require "pathname"
require Pathname(__FILE__).dirname + "helper"

class ResponseTest < Test::Unit::TestCase
  
  def setup
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"
    Harbor::View::layouts.default("layouts/application")
    @response = Harbor::Response.new(Harbor::Test::Request.new)
  end
  
  def teardown
    Harbor::View::path.clear
    Harbor::View::layouts.clear
  end
  
  def test_content_buffer
    @response.puts "Hello World"
    @response.print("Hello World\n")
    assert_equal((["Hello World\n"] * 2), @response.buffer.to_a)
  end

  def test_default_status
    assert_equal(200, @response.status)
  end

  def test_default_content_type
    assert_equal("text/html", @response.content_type)
  end

  def test_set_cookie_with_hash
    cookie_expires_on = Time.now
    expires_gmt_string = cookie_expires_on.gmtime.strftime("%a, %d-%b-%Y %H:%M:%S GMT")

    assert_raise(ArgumentError) { @response.set_cookie(nil, { :value => '1234', :domain => 'www.example.com', :path => '/test', :expires => cookie_expires_on}) }
    assert_raise(ArgumentError) { @response.set_cookie('', { :value => '1234', :domain => 'www.example.com', :path => '/test', :expires => cookie_expires_on}) }

    @response.set_cookie('session_id', { :value => '', :domain => 'www.example.com', :path => '/test', :expires => cookie_expires_on})
    assert_equal("session_id=; domain=www.example.com; path=/test; expires=#{expires_gmt_string}", @response['Set-Cookie'])
    @response['Set-Cookie'] = nil

    @response.set_cookie('session_id', { :value => '1234', :path => '/test', :expires => cookie_expires_on})
    assert_equal("session_id=1234; path=/test; expires=#{expires_gmt_string}", @response['Set-Cookie'])
    @response['Set-Cookie'] = nil

    @response.set_cookie('session_id', { :value => '1234' })
    assert_equal("session_id=1234", @response['Set-Cookie'])
    @response['Set-Cookie'] = nil

    @response.set_cookie('session_id', { :value => '1234', :domain => 'www.example.com', :path => '/test', :expires => cookie_expires_on})
    assert_equal("session_id=1234; domain=www.example.com; path=/test; expires=#{expires_gmt_string}", @response['Set-Cookie'])
    @response['Set-Cookie'] = nil

    @response.set_cookie('session_id', { :http_only => true, :value => '1234', :domain => 'www.example.com', :path => '/test', :expires => cookie_expires_on})
    assert_equal("session_id=1234; domain=www.example.com; path=/test; expires=#{expires_gmt_string}; HTTPOnly=", @response['Set-Cookie'])
    @response['Set-Cookie'] = nil
  end

  def test_standard_headers
    @response.print "Hello World"
    assert_equal({ "Content-Type" => "text/html", "Content-Length" => "Hello World".size.to_s }, @response.headers)
  end

  def test_render_html_view_with_layout
    @response.render "index", :text => "test"
    assert_equal("LAYOUT\ntest\n", @response.buffer)
  end

  def test_render_xml
    @response.render Harbor::XMLView.new("list")
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>Bob</name>\n</site>\n", @response.buffer)
    assert_equal("text/xml", @response.content_type)
  end

  def test_deprecated_multiple_layout_behavior
    result = capture_stderr do
      @response.render "index", :text => "test", :layout => ["layouts/application", "layouts/other"]
    end

    assert_equal("LAYOUT\ntest\n", @response.buffer)
    assert_match /deprecated/, result
  end
  
  def test_errors_is_a_errors_collection
    assert_kind_of(Harbor::Errors, @response.errors)
  end

  def test_cache_requires_block
    assert_raises(ArgumentError) { @response.cache("key", Time.now) }
  end

  def test_cache_sets_last_modified_header
    assert !@response.headers["Last-Modified"]
    modified = Time.now
    @response.cache("key", modified) {}
    assert @response.headers["Last-Modified"]
    assert_equal modified.httpdate, @response.headers["Last-Modified"]
  end

  def test_cache_returns_304_with_matching_if_modified_since_request_header
    time = Time.now
    request = Harbor::Test::Request.new
    request.env["HTTP_IF_MODIFIED_SINCE"] = time.httpdate
    response = Harbor::Response.new(request)

    called = false
    assert_throws(:abort_request) do
      response.cache("key", time) { called = true }
    end
    assert_equal 304, response.status
    assert !called
  end

  def test_cache_yields_with_no_if_modified_since_header
    request = Harbor::Test::Request.new
    response = Harbor::Response.new(request)

    called = false
    response.cache("key", Time.now) { called = true }
    assert called
  end

  def test_cache_yields_with_recent_updated_at
    request = Harbor::Test::Request.new
    request.env["HTTP_IF_MODIFIED_SINCE"] = Time.now.httpdate
    response = Harbor::Response.new(request)

    called = false
    Time.warp(10) do
      response.cache("key", Time.now) { called = true }
    end
    assert called
  end

  def test_cache_raises_argument_error_with_no_cache_configured
    assert_raises(ArgumentError) do
      @response.cache("key", Time.now, 10) {}
    end
  end

  def test_cache_miss_writes_to_cache_store_with_ttl
    with_cache do |cache|
      @response.cache("key", Time.now, 10) { |response| response.puts "Test" }

      item = cache.get("page-key")

      assert item
      assert_equal "Test\n", item.content
    end
  end

  def test_cache_hit_with_ttl_returns_no_content
    with_cache do |cache|
      time = Time.now
      request = Harbor::Test::Request.new
      request.env["HTTP_IF_MODIFIED_SINCE"] = time.httpdate
      response = Harbor::Response.new(request)
      response.cache("key", time, 10) {}

      assert_throws(:abort_request) do
        response.cache("key", time, 10) {}
      end
      assert_equal 304, response.status
    end
  end

  def test_cache_miss_with_modified_since_but_expired_ttl
    with_cache do |cache|
      time = Time.now
      request = Harbor::Test::Request.new
      request.env["HTTP_IF_MODIFIED_SINCE"] = time.httpdate
      response = Harbor::Response.new(request)
      response.cache("key", time, 10) {}

      Time.warp(20) do
        assert_nothing_thrown do
          response.cache("key", time, 10) {}
        end
      end
    end
  end

  def with_cache
    cache = Harbor::Cache.new(Harbor::Cache::Memory.new)
    Harbor::View.cache = cache
    yield cache
  ensure
    cache.delete_matching(/.*/)
    Harbor::View.cache = nil
  end

end