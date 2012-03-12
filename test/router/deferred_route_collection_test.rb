require_relative "../helper"

module Router
  class DeferredRouteCollectionTest < MiniTest::Unit::TestCase
    def setup
      @collection = Harbor::Router::DeferredRouteCollection.new
    end

    def test_replaces_duplicate_deferred_route_uppon_registration
      @collection << Harbor::Router::DeferredRoute.new([':id'], :show)
      @collection << Harbor::Router::DeferredRoute.new([':id'], :duplicate)

      assert_operator @collection.size, :==, 1
      assert_equal :duplicate, @collection.first.action
    end
  end
end
