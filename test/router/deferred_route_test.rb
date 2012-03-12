require_relative "../helper"

module Router
  class DeferredRouteTest < MiniTest::Unit::TestCase
    def test_normalizes_wildcard_routes
      assert_equal ['*'], build_route([':id']).normalized_tokens
    end

    def test_does_not_change_original_tokens
      assert_equal [':id'], build_route([':id']).tokens
    end

    def test_uses_normalized_tokens_for_comparisson
      authors  = build_route(['authors'])
      wildcard = build_route([':id']) # this will result in a "*" which is < 'authors'
      assert_operator wildcard, :<, authors
    end

    def test_assigns_action_uppon_instantiation
      assert_equal :my_action, build_route([], :my_action).action
    end

    def build_route(tokens, action = :action)
      Harbor::Router::DeferredRoute.new(tokens, action)
    end
  end
end
