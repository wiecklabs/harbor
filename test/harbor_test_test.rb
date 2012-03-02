require_relative "helper"
require "harbor/test/test"

class HarborTestTest < MiniTest::Unit::TestCase

  include Harbor::Test

  def setup
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"
  end

  def teardown
    Harbor::View::path.clear
  end

  # ASSERTIONS
  def test_assert_redirect_success
    response = Harbor::Test::Response.new
    response.redirect "/"

    assert_redirect(response)
  end

  def test_assert_redirect_failure
    response = Harbor::Test::Response.new

    assert_raises MiniTest::Assertion do
      assert_redirect(response)
    end
  end

  def test_assert_success_success
    response = Harbor::Test::Response.new

    assert_success(response)
  end

  def test_assert_success_failure
    response = Harbor::Test::Response.new
    response.redirect "/"

    assert_raises MiniTest::Assertion do
      assert_success(response)
    end
  end

  def test_assert_unauthorized_success
    response = Harbor::Test::Response.new
    response.unauthorized

    assert_unauthorized(response)
  end

  def test_assert_unauthorized_failure
    response = Harbor::Test::Response.new

    assert_raises MiniTest::Assertion do
      assert_unauthorized(response)
    end
  end

  def test_request_env_is_not_nil
    container = Harbor::Container.new
    container.set(:request, Harbor::Test::Request)

    request = container.get(:request)

    assert request.env
  end

  def test_request_env_can_be_passed_to_container
    container = Harbor::Container.new
    container.set(:request, Harbor::Test::Request)

    request = container.get(:request, :env => { "REQUEST_METHOD" => "PUT" })

    assert request.env
    assert_equal "PUT", request.env["REQUEST_METHOD"]
    assert_equal "PUT", request.request_method
  end

  def test_response_context_can_be_accessed
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"

    container = Harbor::Container.new
    container.set(:request, Harbor::Test::Request)
    container.set(:response, Harbor::Test::Response)
    response = container.get(:response)

    response.render "index", :var => "test"
    assert_equal response.render_context[:var], "test"
  end

  def test_response_context_can_be_accessed_with_multiple_renders
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"

    container = Harbor::Container.new
    container.set(:request, Harbor::Test::Request)
    container.set(:response, Harbor::Test::Response)
    response = container.get(:response)

    response.render "index", :var => "test1"
    response.render "index", :var => "test2"

    assert_equal response.render_context[:var], "test1"
    assert_equal response.render_context(0)[:var], "test1"
    assert_equal response.render_context(1)[:var], "test2"
  end

  # SESSION
  def test_session
    container = Harbor::Container.new
    container.set(:request, Harbor::Test::Request)

    request = container.get(:request)
    assert_equal Hash.new, request.session.data

    request = container.get(:request, :session => { :user => 1 })
    assert_equal 1, request.session[:user]
  end

  # TEST CONTROLLER
  def test_sample_controller
    controller = Class.new do
      attr_accessor :request, :response

      def hello_world(name)
        response.puts("Hello World. My Name is #{name}.")
      end
    end

    container = Harbor::Container.new
    container.set(:hello_controller, controller)
    container.set(:request, Harbor::Test::Request)
    container.set(:response, Harbor::Test::Response)

    hello = container.get(:hello_controller)
    hello.hello_world("Bob")

    assert_equal "Hello World. My Name is Bob.\n", hello.response.buffer
  end

  def test_controller_with_throw_abort_request
    controller = Class.new do
      attr_accessor :request, :response

      def hello_world(name)
        response.puts "Unauthorized."
        response.unauthorized!
      end
    end

    container = Harbor::Container.new
    container.set(:hello_controller, controller)
    container.set(:request, Harbor::Test::Request)
    container.set(:response, Harbor::Test::Response)

    hello = container.get(:hello_controller)

    assert_throws :abort_request do
      hello.hello_world("Bob")
    end

    assert_unauthorized hello.response
    assert_equal "Unauthorized.\n", hello.response.buffer
  end

end
