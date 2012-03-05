require_relative "helper"

class ControllerTest < MiniTest::Unit::TestCase

  module Controllers
    class Foos < Harbor::Controller

      # /foos
      get do
        :GET
      end

      # /
      get "/" do
        :GET__root__
      end

      # /foos/executive_report
      get "executive_report" do
        :GET_executive_report
      end

      # /foos/42
      get ":id" do
        :GET__id
      end

      # /foos/42/bars
      get ":id/bars" do
        :GET__id_bars
      end

      # /foos/42/bars/1337
      get ":foo_id/bars/:bar_id" do
        :GET__foo_id_bars__bar_id
      end

      # /about_the_foos
      get "/about_the_foos" do
        :GET_about_the_foos
      end

    end
  end

  def setup
    request = Harbor::Test::Request.new
    response = Harbor::Response.new(request)

    @example = Controllers::Foos.new(request, response)
    @router = Harbor::Router::instance
  end

  def test_generated_action_methods_return_expected_results
    assert_equal :GET__root__, @example.GET__root__
    assert_equal :GET, @example.GET
    assert_equal :GET_executive_report, @example.GET_executive_report
    assert_equal :GET__id, @example.GET__id
    assert_equal :GET__id_bars, @example.GET__id_bars
    assert_equal :GET__foo_id_bars__bar_id, @example.GET__foo_id_bars__bar_id
    assert_equal :GET_about_the_foos, @example.GET_about_the_foos
  end

  def test_generated_routes_match_actions
    assert_controller_route_matches("GET", "/", Controllers::Foos, :GET__root__)
    assert_controller_route_matches("GET", "/controller_test/foos", Controllers::Foos, :GET)
    assert_controller_route_matches("GET", "/controller_test/foos/executive_report", Controllers::Foos, :GET_executive_report)
    assert_controller_route_matches("GET", "/controller_test/foos/42", Controllers::Foos, :GET__id)
    assert_controller_route_matches("GET", "/controller_test/foos/42/bars", Controllers::Foos, :GET__id_bars)
    assert_controller_route_matches("GET", "/controller_test/foos/42/bars/1337", Controllers::Foos, :GET__foo_id_bars__bar_id)
    assert_controller_route_matches("GET", "/about_the_foos", Controllers::Foos, :GET_about_the_foos)
  end

end
