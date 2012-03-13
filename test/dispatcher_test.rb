require_relative "helper"

class DispatcherTest < MiniTest::Unit::TestCase
  class TestRouter
    def initialize(route)
      @route = route
    end

    def match(verb, path)
      @route
    end
  end

  def setup
    @action_called = false
    @action        = Proc.new { |request, response| @action_called = (response == @response && request == @request) }
    @route         = Harbor::Router::Route.new(@action, ['parts', ':id', ':order_id'])
    @router        = TestRouter.new(@route)
    @dispatcher    = Harbor::Dispatcher.new(@router)
    @request       = Harbor::Test::Request.new
    @response      = Harbor::Test::Response.new

    @request.path_info = 'parts/1234/4321/'
  end

  def test_extracts_wildcard_params_from_request_path
    @dispatcher.dispatch!(@request, @response)
    assert_equal '1234', @request.params['id']
    assert_equal '4321', @request.params['order_id']
  end

  def test_calls_route_action_with_request_and_response
    @dispatcher.dispatch!(@request, @response)
    assert @action_called
  end
end
