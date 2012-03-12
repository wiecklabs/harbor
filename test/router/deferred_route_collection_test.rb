require_relative "../helper"

module Router
  class DeferredRouteCollectionTest < MiniTest::Unit::TestCase
    def setup
      @collection = Harbor::Router::DeferredRouteCollection.new
    end

    def test_replaces_duplicate_wildcard_route_upon_insertion
      @collection << Harbor::Router::DeferredRoute.new([':id'], :show)
      @collection << Harbor::Router::DeferredRoute.new([':id'], :duplicate)

      assert_operator @collection.wildcard_routes.size, :==, 1
      assert_equal :duplicate, @collection.wildcard_routes.first.action
    end

    def test_replaces_static_route_upon_insertion
      @collection << Harbor::Router::DeferredRoute.new(['posts'], :posts)
      @collection << Harbor::Router::DeferredRoute.new(['posts'], :duplicate)

      assert_operator @collection.static_routes.size, :==, 1
      assert_equal :duplicate, @collection.static_routes.first.action
    end

    def test_clears_static_and_wildcard_routes
      @collection << Harbor::Router::DeferredRoute.new(['posts'], :posts)
      @collection << Harbor::Router::DeferredRoute.new(['posts', ':id'], :show)

      @collection.clear

      assert_predicate @collection.static_routes, :empty?
      assert_predicate @collection.wildcard_routes, :empty?
    end
  end
end
