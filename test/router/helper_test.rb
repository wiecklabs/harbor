require_relative "../helper"

module Router
  class HelperTest < MiniTest::Unit::TestCase    
    def test_index
      assert_helper_called :index, "GET", ""
    end
    
    def test_show
      assert_helper_called :show, "GET", ":id"
    end
    
    def test_create
      assert_helper_called :create, "POST", ""
    end
    
    def test_update
      assert_helper_called :update, "PATCH", ":id"
    end
   
    def test_delete
      assert_helper_called :delete, "DELETE", ":id"
    end
    
    def test_edit
      assert_helper_called :edit, "GET", "edit/:id"
    end
    
    private
    class Stub
      def initialize(mock)
        @mock = mock
      end
      
      include Harbor::Router::Helpers
      
      def route(*args)
        @mock.route(*args)
      end
    end
    
    def assert_helper_called(method, verb, path)
      mock = MiniTest::Mock.new
      # For some reason Mock *requires* an argument to the lambda.
      handler = lambda { |x| true }
      mock.expect(:route, nil, [ verb, path, handler ])
      
      Stub.new(mock).send(method, &handler)
      assert mock.verify
    end
  end
end