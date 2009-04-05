require "pathname"
require Pathname(__FILE__).dirname + "helper"

class ResponseTest < Test::Unit::TestCase
  
  class RequestStub
    def xhr?
      false
    end

    def layout
      "layouts/application"
    end
  end
  
  def setup
    Wheels::View::path.unshift Pathname(__FILE__).dirname + "views"
    @response = Wheels::Response.new(RequestStub.new)
  end
  
  def teardown
    Wheels::View::path.clear
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

  def test_standard_headers
    @response.print "Hello World"
    assert_equal({ "Content-Type" => "text/html", "Content-Length" => "Hello World".size.to_s }, @response.headers)
  end

  def test_render_html_view_with_layout
    @response.render "index", :text => "test"
    assert_equal("LAYOUT\ntest\n", @response.buffer)
  end

  def test_render_xml
    @response.render Wheels::XMLView.new("list")
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>Bob</name>\n</site>\n", @response.buffer)
    assert_equal("text/xml", @response.content_type)
  end
end