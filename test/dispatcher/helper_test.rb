require_relative "../helper"

module Dispatcher
  class HelperTest < MiniTest::Unit::TestCase
    def setup
      @handler = mock
      Harbor.stubs(:new => @handler)
    end

    def teardown
      Harbor::Dispatcher::Helper.instance_variable_set :@instance, nil
    end

    def test_helper_is_present
      assert_kind_of(Harbor::Dispatcher::Helper, harbor)
    end

    def test_dispatches_requests_to_harbor_handler
      @handler.expects(:call).with(has_entries('REQUEST_METHOD' => 'GET', 'PATH_INFO' => '/some/path'))
      harbor.get('some/path')
    end
  end
end
