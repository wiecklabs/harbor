require_relative "../helper"
require 'harbor/router/descriptor'

module Router
  class DescriptorTest < MiniTest::Unit::TestCase
    class SomeController; end

    def setup
      @router = Harbor::Router::instance
      @router.clear!

      @controller = SomeController
    end

    def test_collects_routes_from_all_verb_trees
      register_route 'POST', '/comments'
      register_route 'GET', "/parts"

      assert collect_route_paths.include? '/comments'
      assert collect_route_paths.include? '/parts'
    end

    def test_collects_routes_from_wildcard_nodes
      register_route 'GET', "/parts/:id/orders"
      register_route 'GET', "/parts/:id/:other_id"
      assert collect_route_paths.include? '/parts/:id/orders'
      assert collect_route_paths.include? '/parts/:id/:other_id'
    end

    def test_sorts_routes_based_on_path
      register_route 'GET', "/comments"
      register_route 'GET', "/parts/:id/orders"

      assert_equal '/comments', collect_route_paths.first
      assert_equal '/parts/:id/orders', collect_route_paths.last
    end

    private

    def register_route(verb, path)
      @router.register(verb, path, stub(:controller => SomeController))
    end

    def collect_route_paths
      Harbor::Router::Descriptor.collect_routes.map{|r| r[:path]}
    end
  end
end
