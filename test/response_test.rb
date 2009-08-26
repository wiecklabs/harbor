require "pathname"
require Pathname(__FILE__).dirname + "helper"

class ResponseTest < Test::Unit::TestCase
  
  class RequestStub
    def xhr?
      false
    end
  end
  
  def setup
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"
    Harbor::View::layouts.default("layouts/application")
    @response = Harbor::Response.new(RequestStub.new)
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
end