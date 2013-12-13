require "pathname"
require Pathname(__FILE__).dirname + "helper"

class ApplicationTest < Test::Unit::TestCase

  def setup
    @router = Harbor::Router.new do
      get("/") { |request, response| response.puts "Hello World" }
      get("/exception") { raise "Error in /exception" }
      get("/public-file") { |request, response| response.puts "From Router" }
      post("/") {}
    end

    @request_log = StringIO.new
    @error_log = StringIO.new

    logger = Logging::Logger['request']
    logger.clear_appenders
    logger.add_appenders Logging::Appenders::IO.new('request', @request_log)

    logger = Logging::Logger['error']
    logger.clear_appenders
    error_appender = Logging::Appenders::IO.new('error', @error_log)
    logger.add_appenders error_appender

    logger = Logging::Logger['bad-request']
    logger.clear_appenders
    logger.add_appenders error_appender

    @application = MyApplication.new(Harbor::Container.new, @router)
  end

  def teardown
  end

  def test_call_returns_rack_response_array
    result = @application.call({ "PATH_INFO" => "/", "REQUEST_METHOD" => "GET" })
    assert_equal(200, result[0])
    assert result[1]['Content-Type'] = 'text/html'
    assert result[1]['Content-Length'] = ("Hello World".size + 1).to_s
    assert_equal("Hello World\n", result[2])
  end

  def test_not_found
    status, = @application.call({ "PATH_INFO" => "/", "REQUEST_METHOD" => "DELETE"})
    assert_equal(404, status)

    assert_match(/\(.*404.*\)/, @request_log.string)
  end

  def test_exception
    rack_errors = StringIO.new
    status, = @application.call({
      "PATH_INFO" => "/exception",
      "REQUEST_METHOD" => "GET",
      "rack.errors" => rack_errors,
      "HTTP_HOST" => "",
      "rack.request.form_hash" => {},
      "rack.input" => ""
    })
    assert_equal(500, status)

    assert_match(/Error in \/exception/, @error_log.string)
  end

  def test_find_public_file
    status, headers, body = @application.call({ "PATH_INFO" => "/public-file", "REQUEST_METHOD" => "GET"})
    assert_equal(200, status)

    assert headers.has_key?("Last-Modified")
    assert headers.has_key?("Cache-Control")
    assert_match(/From public/, body.to_s)
  end

  def test_bad_request_rendered_for_invalid_querytring_input
    result = @application.call({
      "PATH_INFO" => "/",
      "REQUEST_METHOD" => "GET",
      "QUERY_STRING" => "somekey=%%"
    })

    assert_match(/bad-request/, @error_log.string)
  end

  def test_bad_request_rendered_for_invalid_post_body
    result = @application.call({
      "PATH_INFO" => "/",
      "REQUEST_METHOD" => "POST",
      "rack.input" => StringIO.new("somekey=%%")
    })

    assert_match(/bad-request/, @error_log.string)
  end

end
