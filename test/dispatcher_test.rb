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
      elsif path.first == 'inner'
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
    @@not_found    = false

    @request.path_info = 'parts/1234/4321/'
  end

  Harbor::Dispatcher.register_event_handler :not_found do
    not_found!
  end

  def self.not_found!
    @@not_found = true
  end

  def test_extracts_wildcard_params_from_request_path
    @dispatcher.dispatch!(@request, @response)
    assert_equal '1234', @request.params['id']
    assert_equal '4321', @request.params['order_id']
  end

  def test_sets_response_to_404_if_non_callable_node_is_matched
    @request.path_info = 'inner/node'
    @dispatcher.dispatch!(@request, @response)
    assert @@not_found
    assert_equal 404, @response.status
  end

  def test_sets_response_to_404_if_no_route_matches
    @request.path_info = 'non/matching/route'
    @dispatcher.dispatch!(@request, @response)
    assert @@not_found
    assert_equal 404, @response.status
  end

  def test_calls_route_action_with_request_and_response
    @dispatcher.dispatch!(@request, @response)
    assert @action_called
  end

  def test_cascades_to_registered_apps_when_no_route_is_matched
    some_app = mock
    some_app.expects(:match).with(@request).returns(true)
    some_app.expects(:call).with(@request, @response)
    @dispatcher.cascade << some_app

    @request.path_info = 'some_app/route'
    @dispatcher.dispatch!(@request, @response)
  end

  def test_support_halting_from_cascading_apps
    some_app = stub(:match => true)
    some_app.stubs(:call).throws(:halt)
    @dispatcher.cascade << some_app

    @request.path_info = 'some_app/route'
    # This will throw an exception if it doesnt catch the throw
    @dispatcher.dispatch!(@request, @response)
  end
end
