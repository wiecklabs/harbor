require_relative 'helper'

class RouterTest < MiniTest::Unit::TestCase

  def setup
    @router = Harbor::Router::instance
    @router.clear!

    @router.register("GET", "/", lambda { :index })
    @router.register("GET", "/parts", lambda { :parts_index })
    @router.register("GET", "/parts/:id", lambda { :get_part_by_id })
    @router.register("GET", "/parts/:id/orders", lambda { :get_orders_for_part })
    @router.register("GET", "/parts/:part_id/orders/:order_id", lambda { :get_order_for_part })
  end

  def test_index_route
    flunk "The new router doesn't support homepages yet"

    assert_equal(:index, @router.match("GET", "/").call)
  end

  def test_non_wildcard_route_matches
    assert_route_matches("GET", "/parts") do |action|
      assert_equal(:parts_index, action.call)
    end
  end

  def test_wildcard_route_matches
    assert_route_matches("GET", "parts/42") do |action|
      assert_equal(:get_part_by_id, action.call)
    end
  end

  def test_route_under_wildcard_matches
    flunk "This fails after having added the 4th route: /parts/:part_id/orders/:order_id"

    assert_route_matches("GET", "parts/42/orders") do |action|
      assert_equal(:get_orders_for_part, action.call)
    end
  end

  def test_route_ending_in_wildcard_matches
    flunk

    assert_route_matches("GET", "parts/42/orders/1337") do |action|
      assert_equal(:get_order_for_part, action.call)
    end
  end

end
