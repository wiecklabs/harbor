#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::Application do

  before do
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

    @application = Helper::MyApplication.new(Harbor::Container.new, @router)
  end

  it "must return rack response Array" do
    result = @application.call({ "PATH_INFO" => "/", "REQUEST_METHOD" => "GET" })
    result[0].must_equal 200
    result[1]['Content-Type'].must_equal "text/html"
    result[1]['Content-Length'].must_equal ("Hello World".size + 1).to_s
    result[2].must_equal "Hello World\n"
  end

  it "must return 404" do
    status, = @application.call({ "PATH_INFO" => "/", "REQUEST_METHOD" => "DELETE"})
    status.must_equal 404
    @request_log.string.must_match /\(.*404.*\)/
  end

  it "must return a 500" do
    rack_errors = StringIO.new
    status, = @application.call({
      "PATH_INFO" => "/exception",
      "REQUEST_METHOD" => "GET",
      "rack.errors" => rack_errors,
      "HTTP_HOST" => "",
      "rack.request.form_hash" => {},
      "rack.input" => ""
    })
    status.must_equal 500
    @error_log.string.must_match /Error in \/exception/
  end

  it "must serve public files" do
    status, headers, body = @application.call({ "PATH_INFO" => "/public-file", "REQUEST_METHOD" => "GET"})
    status.must_equal 200
    headers.must_include "Last-Modified"
    headers.must_include "Cache-Control"
    body.to_s.must_match /From public/
  end

end