require "pathname"
require Pathname(__FILE__).dirname + "helper"

class ResponseTest < Test::Unit::TestCase
  
  def setup
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"
    Harbor::View::layouts.default("layouts/application")
    @request = Harbor::Test::Request.new
    @response = Harbor::Response.new(@request)
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

  ##
  # STREAM_FILE / SEND_FILE
  ##

  def test_stream_file_with_string_io
    @response.stream_file(StringIO.new("test"))

    assert_equal "4", @response.headers["Content-Length"]
    assert_equal "application/octet-stream", @response.headers["Content-Type"]
  end

  def test_stream_file_with_io
    file = File.open(__FILE__)
    @response.stream_file(file)

    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "application/octet-stream", @response.headers["Content-Type"]
  ensure
    file.close
  end

  def test_stream_file_with_filename
    @response.stream_file(__FILE__)

    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  def test_stream_file_with_pathname
    @response.stream_file(Pathname(__FILE__))

    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  def test_stream_file_with_harbor_file
    store = Harbor::FileStore::Local.new(File.dirname(__FILE__))
    file = store.get(File.basename(__FILE__))

    @response.stream_file(file)
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  ##
  # STREAM_FILE / SEND_FILE with X-Sendfile enabled
  ##

  def test_stream_file_with_string_io_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Sendfile"
    @response.stream_file(StringIO.new("test"))

    assert !@response.headers["X-Sendfile"]
    assert_equal "4", @response.headers["Content-Length"]
    assert_equal "application/octet-stream", @response.headers["Content-Type"]
  end

  def test_stream_file_with_io_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Sendfile"
    file = File.open(__FILE__)
    @response.stream_file(file)

    assert !@response.headers["X-Sendfile"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "application/octet-stream", @response.headers["Content-Type"]
  ensure
    file.close
  end

  def test_stream_file_with_filename_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Sendfile"
    @response.stream_file(__FILE__)

    assert_equal __FILE__, @response.headers["X-Sendfile"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  def test_stream_file_with_pathname_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Sendfile"
    @response.stream_file(Pathname(__FILE__))

    assert_equal Pathname(__FILE__).expand_path.to_s, @response.headers["X-Sendfile"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  def test_stream_file_with_harbor_file_and_x_sendfile
    @request.env["HTTP_X_SENDFILE_TYPE"] = "X-Sendfile"
    store = Harbor::FileStore::Local.new(File.dirname(__FILE__))
    file = store.get(File.basename(__FILE__))

    @response.stream_file(file)

    assert_equal __FILE__, @response.headers["X-Sendfile"]
    assert_equal File.size(__FILE__).to_s, @response.headers["Content-Length"]
    assert_equal "text/x-script.ruby", @response.headers["Content-Type"]
  end

  ##
  # CACHE
  ##

  def test_cache_requires_block
    assert_raises(ArgumentError) { @response.cache(nil, Time.now) }
  end

  def test_cache_sets_last_modified_header
    assert !@response.headers["Last-Modified"]
    modified = Time.now
    @response.cache(nil, modified) {}
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
      response.cache(nil, time) { called = true }
    end
    assert_equal 304, response.status
    assert !called
  end

  def test_cache_yields_with_no_if_modified_since_header
    request = Harbor::Test::Request.new
    response = Harbor::Response.new(request)

    called = false
    response.cache(nil, Time.now) { called = true }
    assert called
  end

  def test_cache_yields_with_recent_updated_at
    request = Harbor::Test::Request.new
    request.env["HTTP_IF_MODIFIED_SINCE"] = Time.now.httpdate
    response = Harbor::Response.new(request)

    called = false
    Time.warp(10) do
      response.cache(nil, Time.now) { called = true }
    end
    assert called
  end

  def test_cache_raises_argument_error_with_no_cache_configured
    assert_raises(ArgumentError) do
      @response.cache("key", Time.now, 10) {}
    end
  end

  def test_cache_with_ttl_sets_cache_control_without_store
    @response.cache(nil, Time.now, 10) { |response| response.puts "Test" }

    assert_equal "max-age=10, must-revalidate", @response.headers["Cache-Control"]
  end

  def test_cache_with_ttl_sets_cache_control_with_store
    with_cache do |cache|
      @response.cache("key", Time.now, 10) { |response| response.puts "Test" }

      assert_equal "max-age=10, must-revalidate", @response.headers["Cache-Control"]
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

  ##
  # Messages
  ##

  def test_redirect_without_session
    response = Harbor::Test::Response.new
    request = Harbor::Test::Request.new
    response.request = request

    response.message("error", "Error")
    response.redirect("/redirect", {})
    assert_equal "/redirect?messages%5Berror%5D=Error", response.headers["Location"]
  end

  def test_redirect_with_session
    response = Harbor::Test::Response.new
    request = Harbor::Test::Request.new
    request.session = Harbor::Test::Session.new
    response.request = request

    response.message("error", "Error")
    response.redirect("/redirect", {})
    assert_equal "/redirect", response.headers["Location"]
  end
  
  def test_redirect_with_encoded_url_and_params
    response = Harbor::Test::Response.new
    request = Harbor::Test::Request.new
    response.request = request
    
    response.message("error", "Error")
    response.redirect("/redirect?key=Stuff", {})
    assert_equal "/redirect?messages%5Berror%5D=Error&key=Stuff", response.headers["Location"]
  end

  private

  def with_cache
    cache = Harbor::Cache.new(Harbor::Cache::Memory.new)
    Harbor::View.cache = cache
    yield cache
  ensure
    cache.delete_matching(/.*/)
    Harbor::View.cache = nil
  end

end