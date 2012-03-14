require_relative "../helper"

module Router
  class RouteNodeTest < MiniTest::Unit::TestCase
    RouteNode = Harbor::Router::RouteNode

    def setup
      @node = RouteNode.new
      @node.insert(:index, ['posts'])
    end

    def test_assigns_values_if_blank_inserting_a_single_token
      assert_equal 'posts', @node.fragment
      assert_equal :index, @node.action
      assert_equal ['posts'], @node.tokens
    end

    def test_inserts_node_on_the_left
      @node.insert(:action, ['categories'])
      assert_equal 'categories', @node.left.fragment
      assert_equal :action, @node.left.action
      assert_equal ['categories'], @node.left.tokens
    end

    def test_inserts_node_on_the_right
      @node.insert(:action, ['tags'])
      assert_equal 'tags', @node.right.fragment
      assert_equal :action, @node.right.action
      assert_equal ['tags'], @node.right.tokens
    end

    def test_creates_match_node
      @node.insert(:action, [@node.fragment, 'id'])
      assert_equal 'id', @node.match.fragment
      assert_equal :action, @node.match.action
      assert_equal ['posts', 'id'], @node.match.tokens
    end

    def test_creates_required_virtual_nodes
      @node.insert(:action, ['categories', 'id'])
      assert_equal 'categories', @node.left.fragment
      assert_equal nil, @node.left.action
    end

    def test_updates_virtual_nodes_with_new_action
      @node.insert(:id_action, ['categories', 'id'])
      @node.insert(:categories_action, ['categories'])
      assert_equal :categories_action, @node.left.action
    end

    def test_identifies_wildcard_fragment
      assert RouteNode.wildcard_fragment?('*')
      refute RouteNode.wildcard_fragment?('posts')
    end

    def test_handles_multiple_wildcard_tokens_under_match_node
      id = @node.insert(:id, ['posts', ':id'])
      comments = @node.insert(:comments, ['posts', ':post_id', 'comments'])

      assert_equal id, @node.match
      assert_equal comments, @node.match.match
    end

    def test_updates_wildcard_virtual_nodes_with_action_and_tokens
      @node.insert(:comments, ['posts', ':post_id', 'comments'])
      @node.insert(:id, ['posts', ':id'])

      assert_equal :id, @node.match.action
      assert_equal ['posts', ':id'], @node.match.tokens
    end

    def test_handles_nested_wildcard_tokens
      id_node = @node.insert(:id, ['posts', ':id'])
      comment_node = @node.insert(:comment, ['posts', ':post_id', ':comment_id'])

      assert_equal id_node, @node.match
      assert_equal comment_node, @node.match.match
    end

    def test_handles_non_wildcard_routes_precedence_by_replacing_node
      show = @node.insert(:id, ['posts', ':id'])
      recent = @node.insert(:recent, ['posts', 'recent'])

      assert_kind_of Harbor::Router::WildcardNode, @node.match
      assert_same show, @node.match.wildcard_tree
      assert_same recent, @node.match.trees['recent']
    end

    def test_handles_non_wildcard_routes_precedence_by_replacing_nodes
      recent = @node.insert(:recent, ['posts', 'recent'])
      show = @node.insert(:id, ['posts', ':id'])

      assert_kind_of Harbor::Router::WildcardNode, @node.match
      assert_same show, @node.match.wildcard_tree
      assert_same recent, @node.match.trees['recent']
    end

    def test_finds_node_on_the_right
      @node.insert(:recent, ['tags'])
      @node.insert(:videos, ['videos'])

      assert_equal :videos, @node.search(['videos']).action
    end

    def test_finds_node_on_the_left
      @node.insert(:categories, ['categories'])
      @node.insert(:authors, ['authors'])

      assert_equal :authors, @node.search(['authors']).action
    end

    def test_finds_matching_nodes
      @node.insert(:categories, ['posts', 'categories'])

      assert_equal :categories, @node.search(['posts', 'categories']).action
    end

    def test_finds_wildcard_matching_nodes
      @node.insert(:show, ['posts', ':id'])

      assert_equal :show, @node.search(['posts', '1234']).action
    end

    def test_return_nil_if_cant_be_found
      assert_nil @node.search(['whaaat?'])
    end
  end
end
