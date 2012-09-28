require_relative '../helper'

module Dispatcher
  class RackWrapperTest < MiniTest::Unit::TestCase
    def setup
      @app = Class.new do
        def call(env)
          [404, {'Content-Type' => 'xml'}, 'Hello Harbor']
        end
      end.new

      @response = Harbor::Test::Response.new
      @request  = Harbor::Test::Request.new
      @wrapper  = Harbor::Dispatcher::RackWrapper
    end

    def test_calls_inner_app_with_request_env
      @app.expects(:call).with(@request.env)
      @wrapper.call(@app, @request, @response)
    end

    def test_sets_response_status
      @wrapper.call(@app, @request, @response)
      assert_equal 404, @response.status
    end

    def test_sets_response_headers
      @wrapper.call(@app, @request, @response)
      assert_equal({'Content-Type' => 'xml'}, @response.headers)
    end

    def test_sets_response_buffer
      @wrapper.call(@app, @request, @response)
      assert_equal 'Hello Harbor', @response.buffer
    end
  end
end
