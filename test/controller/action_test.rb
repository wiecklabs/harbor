require_relative '../helper'

module Controller
  class ActionTest < MiniTest::Unit::TestCase

    class TestController
      def initialize(*args); end

      def action
        :action_result
      end

      def action_with_args(first, second)
        [first, second]
      end

      def action_with_default(required, default = 'default')
        [required, default]
      end
    end

    def setup
      @action              = Harbor::Controller::Action.new(TestController, :action)
      @action_with_args    = Harbor::Controller::Action.new(TestController, :action_with_args)
      @action_with_default = Harbor::Controller::Action.new(TestController, :action_with_default)

      @request    = Harbor::Test::Request.new
      @response   = Harbor::Test::Response.new
    end

    def test_calls_simple_action
      assert_equal :action_result, @action.call(@request, @response)
    end

    def test_calls_action_with_args
      @request.params = {'first' => 1, 'second' => 2}
      assert_equal [1, 2], @action_with_args.call(@request, @response)
    end

    def test_calls_action_with_optional_args
      @request.params = {'required' => 1}
      assert_equal [1, 'default'], @action_with_default.call(@request, @response)
    end

    def test_calls_action_with_optional_args
      @request.params = {'required' => 1}
      assert_equal [1, 'default'], @action_with_default.call(@request, @response)
    end

    def test_raises_abort_request_if_a_required_argument_is_not_provided
      assert_throws(:abort_request) { @action_with_args.call(@request, @response) }
    end

    def test_set_response_status_to_400_when_aborting_request
      catch(:abort_request) { @action_with_args.call(@request, @response) }
      assert_equal 400, @response.status
    end
  end
end
