require_relative "../helper"

module Router
  class WildcardNodeTest < MiniTest::Unit::TestCase
    def setup
      @node = Harbor::Router::WildcardNode.new
      @simple_node = Harbor::Router::RouteNode.new(nil, nil, 'parts')
      @wild_node = Harbor::Router::RouteNode.new(nil, nil, ':id')
    end

    def test_creates_tree_entry_for_exact_matches_when_initialized
      node = Harbor::Router::WildcardNode.new(@simple_node)
      refute_nil node.trees['parts']
    end

    def test_creates_wildcard_tree_when_extended
      node = Harbor::Router::WildcardNode.new(@wild_node)
      refute_nil node.wildcard_tree
    end

    def test_delegates_insertion_to_inner_trees
      node = Harbor::Router::WildcardNode.new(@simple_node)
      created_node = node.find_or_create_node!([@simple_node.fragment, ':id'])

      assert_same created_node, @simple_node.match
    end

    def test_delegates_insertion_to_wildcard_tree
      node = Harbor::Router::WildcardNode.new(@wild_node)
      created_node = node.find_or_create_node!([':foo', 'edit'])

      assert_same created_node, @wild_node.match
    end

    def test_exact_matches_take_precedence
      @node.find_or_create_node!(['parts', ':id'])
      @node.find_or_create_node!([':id', 'comments'])

      assert_equal '*', @node.search(['parts', 'comments']).fragment
    end

    def test_finds_wildcard_match
      @node.find_or_create_node!(['parts', ':id'])
      @node.find_or_create_node!([':id', 'comments'])

      assert_equal 'comments', @node.search(['foo', 'comments']).fragment
    end

    def test_retries_search_with_wildcard_matches
      @node.find_or_create_node!(['a', 'b', 'c'])
      @node.find_or_create_node!([':a', ':b', ':c'])

      assert_equal '*', @node.search(['a', 'b', 'd']).fragment
    end
  end
end
