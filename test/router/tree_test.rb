require_relative "../helper"

module Router
  class TreeTest < MiniTest::Unit::TestCase
    def setup
      @tree = Harbor::Router::Tree.new
    end

    def test_creates_home_node_if_tokens_are_empty
      @tree.insert([], :home)
      assert_equal :home, @tree.home.action
    end

    def test_replaces_home_node_with_new_node
      @tree.insert([], :home).insert([], :new_home)
      assert_equal :new_home, @tree.home.action
    end

    def test_delegates_insertion_to_root_node
      mock = MiniTest::Mock.new
      mock.expect :insert, nil, [:action, ['posts']]
      @tree.instance_variable_set(:@root, mock)

      @tree.insert(['posts'], :action)

      assert mock.verify
    end

    def test_delegates_search_to_root_node
      mock = MiniTest::Mock.new
      mock.expect :search, Harbor::Router::Route.new(:search_result), [['posts']]
      @tree.instance_variable_set(:@root, mock)

      assert_equal :search_result, @tree.search(['posts'])
    end

    def test_matches_home_route_if_registered
      @tree.insert([], :home)
      assert_equal :home, @tree.search([])
    end
  end
end
