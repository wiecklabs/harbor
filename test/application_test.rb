require "helper"

class ApplicationTest < Test::Unit::TestCase

  class MyApplication < Wheels::Application
    def self.public_path
      Pathname(__FILE__).dirname + "public"
    end
  end

  def setup
    @router = Wheels::Router.new do
      get("/") { |request, response| response.puts "Hello World" }
      get("/exception") { raise "Error in /exception" }
      get("/public-file") { |request, response| response.puts "From Router" }
      post("/") {}
    end

    @old_stderr = $stderr
    $stderr = StringIO.new

    @old_stdout = $stdout
    $stdout = StringIO.new

    @application = MyApplication.new(@router)
  end

  def teardown
    $stderr = @old_stderr
    $stdout = @old_stdout
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

    $stdout.seek(0)
    assert_match(/\(404\)/, $stdout.read)
  end

  def test_exception
    status, = @application.call({
      "PATH_INFO" => "/exception",
      "REQUEST_METHOD" => "GET",
      "rack.errors" => $stderr,
      "HTTP_HOST" => "",
      "rack.request.form_hash" => {}
    })
    assert_equal(500, status)

    $stderr.seek(0)
    assert_match(/Error in \/exception/, $stderr.read)
  end

  def test_find_public_file
    status, type, body = @application.call({ "PATH_INFO" => "/public-file", "REQUEST_METHOD" => "GET"})
    assert_equal(200, status)

    assert_match(/From public/, body.to_s)
  end

end