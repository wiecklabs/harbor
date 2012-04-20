require_relative '../helper'

module Controller
  class ActionFilterTest < MiniTest::Unit::TestCase
    ActionFilter = Harbor::Controller::ActionFilter

    def setup
      @request = Harbor::Test::Request.new
      @request.request_method = :get
      @controller_class = Class.new
      @controller = mock
      @controller.stubs(request: @request)
    end

    def stub_normalization(value)
      Harbor::Controller::NormalizedPath.stubs(:new => value)
    end

    def test_evaluates_block_in_the_context_of_a_controller
      @controller.expects(:some_filter)
      ActionFilter.new(@controller_class, :all) { self.some_filter }.filter! @controller
    end

    def test_calls_instance_method_if_call_key_is_present
      @controller.expects(:auth)
      ActionFilter.new(@controller_class, :all, :call => :auth).filter! @controller
    end

    def test_filters_based_on_path
      @request.path_info = '/my_controller/1'
      @controller.expects(:auth)
      stub_normalization('my_controller/:id')
      ActionFilter.new(@controller_class, ':id', :call => :auth).filter! @controller

      @request.path_info = '/admin/whatever/path'
      @controller.expects(:log)
      stub_normalization('admin/*')
      ActionFilter.new(@controller_class, '/admin/*', :call => :log).filter! @controller

      @request.path_info = '/my_controller/1'
      stub_normalization('my_controller')
      ActionFilter.new(@controller_class, :call => :raise_undefined).filter! @controller

      @controller.expects(:root_filter)
      @request.path_info = '/'
      stub_normalization('')
      ActionFilter.new(@controller_class, '/', :call => :root_filter).filter! @controller
    end

    def test_filters_based_on_request_method
      @controller.expects(:auth)
      ActionFilter.new(@controller_class, :all, :request_method => :get, :call => :auth).filter! @controller
      ActionFilter.new(@controller_class, :all, :request_method => :put, :call => :undefined).filter! @controller
    end
  end
end
