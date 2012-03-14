require_relative "../helper"

module Router
  class RouteTest < MiniTest::Unit::TestCase
    Route = Harbor::Router::Route

    def test_identifies_wildcard_tokens
      assert Route.wildcard_token?(':post_id')
      refute Route.wildcard_token?('posts')
    end
  end
end
