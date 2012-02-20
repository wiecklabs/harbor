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
          
    end
  end
  
  def setup
    request = Harbor::Test::Request.new
    response = Harbor::Response.new(request)
    @example = Controllers::Example.new(request, response)
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
  
end