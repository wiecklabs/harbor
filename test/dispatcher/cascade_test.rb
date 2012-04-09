require_relative '../helper'

module Dispatcher
  class CascadeTest < MiniTest::Unit::TestCase
    def setup
      @request = mock
      @app     = stub(:match => nil, :call => nil)
      @cascade = Harbor::Dispatcher::Cascade.new
      @cascade << @app
    end

    def test_raises_argument_error_if_app_does_not_respond_to_match
      app = stub(:call => nil)
      assert_raises ArgumentError do
        @cascade << app
      end
    end

    def test_raises_argument_error_if_app_does_not_respond_to_call
      app = stub(:match => nil)
      assert_raises ArgumentError do
        @cascade << app
      end
    end

    def test_delegates_match_to_registered_apps
      @app.expects(:match).with(@request)
      @cascade.match(@request)
    end

    def test_returns_first_registered_app_that_matches
      other_app = stub(:match => true, :call => nil)
      @cascade << other_app
      assert_same other_app, @cascade.match(@request)
    end

    def test_unregisters_apps
      @cascade.unregister(@app)
      assert_equal 0, @cascade.apps.size
    end

    def test_registers_apps_only_once
      @cascade << @app
      assert_equal 1, @cascade.apps.size
    end
  end
end
