require "pathname"
require Pathname(__FILE__).dirname + "helper"

class ControllerRouterTest < Test::Unit::TestCase
  
  module Controllers
    class Example < Harbor::Controller
    
      def GET_test_one
        :one
      end
    
      def GET_test_two
        :two
      end
    
      def GET_test_three
        :three
      end
    
      def self.get(route = "", &block)
        action_name = method_name_for_route("GET", route)
        define_method(action_name, &block)
        Harbor::Controller::Router::instance.register("GET", absolute_route_path(self, route), self, action_name)
      end
    
      get(":id") { }
    
      get("/:id") { }
    end
  end
  
  def test_path_matches
    router = Harbor::Controller::Router.new
    
    router.register("GET", "/example/test/one", Controllers::Example, :GET_test_one)
    router.register("GET", "/example/test/two", Controllers::Example, :GET_test_two)
    router.register("GET", "/example/test/three", Controllers::Example, :GET_test_three)
    
    return
    assert_equal(:one, router.match("GET", "/example/test/one").call)
    assert_equal(:two, router.match("GET", "/example/test/two").call)
    assert_equal(:three, router.match("GET", "/example/test/three").call)
  end
  
  def test_paths_are_made_absolute
    assert_equal "controller_router_test/example/:id",
      Harbor::Controller.send(:absolute_route_path, Controllers::Example, ":id")
      
    assert_equal "example/:id/edit",
      Harbor::Controller.send(:absolute_route_path, Controllers::Example, "/example/:id/edit")
  end
  
end