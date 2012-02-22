require "pathname"
require Pathname(__FILE__).dirname + "helper"

class ControllerRouterTest < Test::Unit::TestCase
  
  module Controllers
    class Example < Harbor::Controller
      
      get "test/one" do
        :one
      end
      
      get "test/two" do
        :two
      end
      
      get "test/three" do
        :three
      end
      
      get "foo" do
        :foo
      end
      
      get "foo/:bar" do
        :bar
      end
      
      get "/foo/:bar/baz" do
        :baz
      end
          
    end
  end
  
  def setup
    request = Harbor::Test::Request.new
    response = Harbor::Response.new(request)
    @example = Controllers::Example.new(request, response)
    
    @router = Harbor::Controller::Router::instance
  end
  
  def test_method_generation
    assert(Controllers::Example.instance_method(:GET_test_one))
    assert(Controllers::Example.instance_method(:GET_test_two))
    assert(Controllers::Example.instance_method(:GET_test_three))
  end
  
  def test_method_result
    assert_equal :one, @example.GET_test_one
    assert_equal :two, @example.GET_test_two
    assert_equal :three, @example.GET_test_three
  end
  
  def test_paths_are_made_absolute
    assert_equal "controller_router_test/example/:id",
      Harbor::Controller.send(:absolute_route_path, Controllers::Example, ":id")
      
    assert_equal "example/:id/edit",
      Harbor::Controller.send(:absolute_route_path, Controllers::Example, "/example/:id/edit")
  end
  
  def test_action_is_matched
    one   = @router.match("GET", "controller_router_test/example/test/one")
    two   = @router.match("GET", "controller_router_test/example/test/two")
    three = @router.match("GET", "controller_router_test/example/test/three")
    
    assert_equal(Controllers::Example, one.controller)
    assert_equal(Controllers::Example, two.controller)
    assert_equal(Controllers::Example, three.controller)
    
    assert_equal(:GET_test_one, one.name)
    assert_equal(:GET_test_two, two.name)
    assert_equal(:GET_test_three, three.name) 
  end
  
  def test_action_with_wildcards_are_matched
    foo   = @router.match("GET", "controller_router_test/example/foo")
    bar   = @router.match("GET", "controller_router_test/example/foo/cow")
    baz   = @router.match("GET", "foo/moo/baz")
    
    assert_equal(Controllers::Example, foo.controller)
    assert_equal(Controllers::Example, bar.controller)
    assert_equal(Controllers::Example, baz.controller)
    
    assert_equal(:GET_foo, foo.name)
    assert_equal(:GET_foo__bar, bar.name)
    assert_equal(:GET_foo__bar_baz, baz.name) 
  end
end