require "pathname"
require Pathname(__FILE__).dirname + "helper"

class ApplicationTest < Test::Unit::TestCase

  class MyApplication < Harbor::Application
    def self.public_path
      Pathname(__FILE__).dirname + "public"
    end
  end

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
    logger.add_appenders Logging::Appenders::IO.new('error', @error_log)

    @application = MyApplication.new(Harbor::Container.new, @router)
  end

  def teardown
  end

  def test_call_returns_rack_response_array
    result = @application.call({ "PATH_INFO" => "/", "REQUEST_METHOD" => "GET" })
    assert_equal(200, result[0])
    assert_equal({ "Content-Type" => "text/html", "Content-Length" => ("Hello World".size + 1).to_s }, result[1])
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
      "rack.request.form_hash" => {}
    })
    assert_equal(500, status)

    assert_match(/Error in \/exception/, @error_log.string)
  end

  def test_find_public_file
    status, type, body = @application.call({ "PATH_INFO" => "/public-file", "REQUEST_METHOD" => "GET"})
    assert_equal(200, status)

    assert_match(/From public/, body.to_s)
  end

end