#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::Test do
  include Harbor::Test

  it "must assert redirect" do
    response = Harbor::Test::Response.new
    response.redirect "/"

    -> { assert_redirect(response) }.wont_raise
  end

  it "must assert redirect failure" do
    response = Harbor::Test::Response.new

    -> { assert_redirect(response) }.must_raise MiniTest::Assertion
  end

  it "must assert success" do
    response = Harbor::Test::Response.new

    -> { assert_success(response) }.wont_raise
  end

  it "must assert success failure" do
    response = Harbor::Test::Response.new
    response.redirect "/"

    -> { assert_success(response) }.must_raise MiniTest::Assertion
  end

  it "must assert unauthorized" do
    response = Harbor::Test::Response.new
    response.unauthorized

    -> { assert_unauthorized(response) }.wont_raise
  end

  it "must assert unauthorized failure" do
    response = Harbor::Test::Response.new

    -> { assert_unauthorized(response) }.must_raise MiniTest::Assertion
  end

  it "must not have a nil env" do
    container = Harbor::Container.new
    container.register(:request, Harbor::Test::Request)

    request = container.get(:request)

    request.env.wont_be_nil
  end

  it "must let env be overridden" do
    container = Harbor::Container.new
    container.register(:request, Harbor::Test::Request)

    request = container.get(:request, :env => { "REQUEST_METHOD" => "PUT" })

    request.env.wont_be_nil

    request.env["REQUEST_METHOD"].must_equal "PUT"
    request.request_method.must_equal "PUT"
  end

  it "must let response context be accessed" do
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"

    container = Harbor::Container.new
    container.register(:request, Harbor::Test::Request)
    container.register(:response, Harbor::Test::Response)
    response = container.get(:response)
    
    response.render "index", :var => "test"

    response.render_context[:var].must_equal "test"
  end

  it "must let response context be accessed with multiple render calls" do
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"

    container = Harbor::Container.new
    container.register(:request, Harbor::Test::Request)
    container.register(:response, Harbor::Test::Response)
    response = container.get(:response)
    
    response.render "index", :var => "test1"
    response.render "index", :var => "test2"

    response.render_context[:var].must_equal "test1"
    response.render_context(0)[:var].must_equal "test1"
    response.render_context(1)[:var].must_equal "test2"
  end

  # SESSION
  it "must provide a session" do
    container = Harbor::Container.new
    container.register(:request, Harbor::Test::Request)

    request = container.get(:request)
    request.session.data.must_equal Hash.new

    request = container.get(:request, :session => { :user => 1 })
    request.session[:user].must_equal 1
  end

  # TEST CONTROLLER
  it "must test a controller" do
    controller = Class.new do
      attr_accessor :request, :response

      def hello_world(name)
        response.puts("Hello World. My Name is #{name}.")
      end
    end

    container = Harbor::Container.new
    container.register(:hello_controller, controller)
    container.register(:request, Harbor::Test::Request)
    container.register(:response, Harbor::Test::Response)

    hello = container.get(:hello_controller)
    hello.hello_world("Bob")

    hello.response.buffer.must_equal "Hello World. My Name is Bob.\n"
  end

  it "must throw an abort_request in the controller" do
    controller = Class.new do
      attr_accessor :request, :response

      def hello_world(name)
        response.puts "Unauthorized."
        response.unauthorized!
      end
    end

    container = Harbor::Container.new
    container.register(:hello_controller, controller)
    container.register(:request, Harbor::Test::Request)
    container.register(:response, Harbor::Test::Response)

    hello = container.get(:hello_controller)

    -> { hello.hello_world("Bob") }.must_throw :abort_request

    assert_unauthorized hello.response
    hello.response.buffer.must_equal "Unauthorized.\n"
  end

end