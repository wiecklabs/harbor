require_relative "../helper"

module Router
  class WildcardRouteTest < MiniTest::Unit::TestCase
    def setup
      @node = Harbor::Router::Route.new
    end

    def test_creates_tree_entry_for_exact_matches_when_extended
      @node.insert(:exact, ['parts'])
      @node.insert(:wild, [':id'])

      assert_equal :exact, @node.trees['parts'].action
    end

    def test_creates_wildcard_tree_when_extended
      @node.insert(:wild, [':id'])
      @node.insert(:exact, ['parts'])

      assert_equal :wild, @node.wildcard_tree.action
    end

    def test_delegates_insertion_to_inner_trees
      @node.insert(:wild, [':id'])
      @node.insert(:exact, ['parts'])
      @node.insert(:inner_wild, ['parts', ':id'])

      assert_equal :inner_wild, @node.trees['parts'].match.action
    end

    def test_delegates_insertion_to_wildcard_tree
      @node.insert(:exact, ['parts'])
      @node.insert(:wild, [':id'])
      @node.insert(:wild_with_exact, [':id', 'orders'])

      assert_equal :wild_with_exact, @node.wildcard_tree.match.action
    end

    def test_updates_exact_matches_upon_insertion
      @node.insert(:wild, [':id'])
      @node.insert(:inner_wild, ['parts', ':id'])
      @node.insert(:action, ['parts'])

      assert_equal :action, @node.trees['parts'].action
      assert_equal ['parts'], @node.trees['parts'].tokens
    end

    def test_updates_wildcard_matches_upon_insertion
      @node.insert(:exact, ['parts'])
      @node.insert(:wild_with_exact, [':id', 'orders'])
      @node.insert(:action, [':id'])

      assert_equal :action, @node.wildcard_tree.action
      assert_equal [':id'], @node.wildcard_tree.tokens
    end

    def test_exact_matches_take_precedence
      @node.insert(:show, ['parts', ':id'])
      @node.insert(:comments, [':id', 'comments'])

      assert_equal :show, @node.search(['parts', '1234']).action
    end

    def test_finds_wildcard_match
      @node.insert(:show, ['parts', ':id'])
      @node.insert(:comments, [':id', 'comments'])

      assert_equal :comments, @node.search(['foo', 'comments']).action
    end

    def test_retries_search_with_wildcard_matches
      @node.insert(:all_exact, ['a', 'b', 'c'])
      @node.insert(:all_wild, [':a', ':b', ':c'])

      assert_equal :all_wild, @node.search(['a', 'b', 'd']).action
    end
  end
end
