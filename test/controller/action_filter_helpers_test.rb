require_relative "../helper"

module Controller
  class ActionFilterHelperTest < MiniTest::Unit::TestCase
    class TestController
      include Harbor::Controller::ActionFilterHelpers
    end

    def setup
      @controller_class = TestController
    end

    def teardown
      @controller_class.filters[:before] = []
      @controller_class.filters[:after] = []
    end

    def test_registers_before_and_after_filters
      @controller_class.before :some_filter_method
      @controller_class.after :some_other_filter_method

      assert_equal 1, @controller_class.filters[:before].size
      assert_equal 1, @controller_class.filters[:after].size
    end

    def test_creates_instances_of_action_filters
      a_block = lambda { nil }
      Harbor::Controller::ActionFilter.expects(:new).with(@controller_class, :list_of_args, a_block)
      @controller_class.before :list_of_args, &a_block
    end

    def test_delegates_filtering_to_registered_filters_based_on_type
      filter_mock = mock('a filter')
      @controller_class.filters[:before] << filter_mock

      controller = @controller_class.new
      filter_mock.expects(:filter!).with(controller)
      controller.filter!(:before)
    end
  end
end
