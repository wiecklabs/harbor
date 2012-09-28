require_relative '../helper'

module Controller
  class ActionTest < MiniTest::Unit::TestCase

    class TestController
      def action; end
      def action_with_args(first, second); end
      def action_with_default(required, default = 'default') end
      def filter!(*args); end
    end

    def setup
      @action              = Harbor::Controller::Action.new(TestController, :action)
      @action_with_args    = Harbor::Controller::Action.new(TestController, :action_with_args)
      @action_with_default = Harbor::Controller::Action.new(TestController, :action_with_default)

      @request    = Harbor::Test::Request.new
      @response   = Harbor::Test::Response.new

      @controller = TestController.new
      config.stubs(:get => @controller)
    end

    def test_action_initializes_controller_through_container
      config.expects(:get).
        with(TestController.name, "request" => @request, "response" => @response).
        returns(@controller)
      @action.call(@request, @response)
    end

    def test_calls_simple_action
      @controller.expects(:action).with()
      @action.call(@request, @response)
    end

    def test_calls_action_with_args
      @controller.expects(:action_with_args).with(1, 2)
      @request.params = {'first' => 1, 'second' => 2}
      @action_with_args.call(@request, @response)
    end

    def test_calls_action_with_optional_args
      @controller.expects(:action_with_default).with(1)
      @request.params = {'required' => 1}
      @action_with_default.call(@request, @response)
    end

    def test_raises_halt_if_a_required_argument_is_not_provided
      assert_throws(:halt) { @action_with_args.call(@request, @response) }
    end

    def test_set_response_status_to_400_when_halting
      catch(:halt) { @action_with_args.call(@request, @response) }
      assert_equal 400, @response.status
    end
  end
end
