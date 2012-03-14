require_relative "../helper"

module Router
  class HttpVerbRouterTest < MiniTest::Unit::TestCase
    def setup
      @tree = Harbor::Router::HttpVerbRouter.new
    end

    def test_creates_static_route
      @tree.register(['static', 'route'], :static)
      assert_equal :static, @tree.static_routes['static/route'].action
    end

    def test_replaces_static_route_with_new_route
      @tree.register(['static'], :static).register(['static'], :new_static)
      assert_equal :new_static, @tree.static_routes['static'].action
    end

    def test_delegates_wildcard_insertion_to_root_node
      mock = MiniTest::Mock.new
      mock.expect :insert, nil, [:action, [':id'], @tree.send('root_parent')]
      @tree.instance_variable_set(:@root, mock)

      @tree.register([':id'], :action).
        build!

      assert mock.verify
    end

    def test_delegates_search_to_root_node
      mock = MiniTest::Mock.new
      mock.expect :search, Harbor::Router::Route.new(:search_result), [['1234']]
      @tree.instance_variable_set(:@root, mock)

      assert_equal :search_result, @tree.search(['1234']).action
    end

    def test_finds_static_routes
      @tree.register(['posts'], :posts)
      assert_equal :posts, @tree.search(['posts']).action
    end

    def test_finds_wildcard_routes
      @tree.register([':id'], :show)
      assert_equal :show, @tree.search(['1234']).action
    end

    def test_static_routes_preceds_wildcard
      @tree.register(['posts'], :posts).
        register([':id'], :wildcard)

      assert_equal :posts, @tree.search(['posts']).action
    end

    def test_builds_a_deferred_route_collection
      assert_instance_of Harbor::Router::DeferredRouteCollection, @tree.deferred_routes
    end

    def test_registers_deferred_routes
      @tree.register([':id'], :show)
      refute_predicate @tree.deferred_routes, :blank?
    end

    def test_builds_a_balanced_tree_using_deferred_wildcard_routes
      @tree.register(['authors', ':id'], :authors).
        register(['comments', ':id'], :comments).
        register(['posts', ':id'], :posts).
        build!

      assert_equal :comments, @tree.root.match.action
      assert_equal :authors, @tree.root.left.match.action
      assert_equal :posts, @tree.root.right.match.action
    end

    def test_empties_deferred_routes_after_building
      @tree.register(['authors'], :authors).
        register([':id'], :show).
        build!

      assert_operator @tree.deferred_routes.size, :==, 0
    end

    def test_build_deferred_routes_before_searching
      @tree.register([':id'], :show)

      @tree.search(['1234'])
      refute_nil @tree.root
    end

    def test_handles_collision_on_root_node
      @tree.register([':id'], :show)
      @tree.register(['posts', ':id'], :posts)
      @tree.build!

      assert_kind_of Harbor::Router::WildcardNode, @tree.root
    end
  end
end
