require_relative "helper"

class DispatcherTest < MiniTest::Unit::TestCase
  class TestRouter
    def initialize(route, empty_route)
      @route = route
      @empty_route = empty_route
    end

    def match(verb, path)
      if path.first == 'parts'
        @route
      else
        @empty_route
      end
    end
  end

  def setup
    @action_called = false
    @action        = Proc.new { |request, response| @action_called = (response == @response && request == @request) }
    @route         = Harbor::Router::Route.new(@action, ['parts', ':id', ':order_id'])
    @empty_route   = Harbor::Router::Route.new
    @router        = TestRouter.new(@route, @empty_route)
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

  def test_aborts_request_if_non_callable_node_is_matched
    @request.path_info = 'inner/node'
    assert_throws(:abort_request) { @dispatcher.dispatch!(@request, @response) }
  end

  def test_sets_response_to_404_if_non_callable_node_is_matched
    @request.path_info = 'inner/node'
    catch(:abort_request) { @dispatcher.dispatch!(@request, @response) }
    assert_equal 404, @response.status
  end

  def test_calls_route_action_with_request_and_response
    @dispatcher.dispatch!(@request, @response)
    assert @action_called
  end
end
