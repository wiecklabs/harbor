require_relative "helper"

class DispatcherTest < MiniTest::Unit::TestCase
  class TestRouter
    attr_reader :match_argument

    def initialize(route)
      @route = route
    end

    def match(verb, path)
      @match_argument = path
      @route
    end
  end

  def setup
    @route      = Harbor::Router::Route.new(Proc.new{}, [])
    @router     = TestRouter.new(@route)
    @dispatcher = Harbor::Dispatcher.new(@router)
    @request    = Harbor::Test::Request.new
    @response   = Harbor::Test::Response.new

    @request.path_info = 'parts/1234/4321/'
    @route.tokens << 'parts' << ':id' << ':order_id'
  end

  def test_extracts_wildcard_params_from_request_path
    @dispatcher.dispatch!(@request, @response)
    assert_equal '1234', @request.params['id']
    assert_equal '4321', @request.params['order_id']
  end
end
