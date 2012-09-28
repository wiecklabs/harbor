require_relative "../helper"

module Router
  class DeferredRouteSetTest < MiniTest::Unit::TestCase
    def setup
      @collection = Harbor::Router::DeferredRouteSet.new
    end

    def test_replaces_duplicate_route_upon_insertion
      @collection << Harbor::Router::DeferredRoute.new([':id'], :show)
      @collection << Harbor::Router::DeferredRoute.new([':id'], :duplicate)

      assert_operator @collection.size, :==, 1
      assert_equal :duplicate, @collection.to_a.first.action
    end

    def test_clears_routes
      @collection << Harbor::Router::DeferredRoute.new(['posts', ':id'], :show)

      @collection.clear

      assert_predicate @collection, :empty?
    end
  end
end
