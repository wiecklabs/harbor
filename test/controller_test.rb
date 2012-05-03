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

      # /
      post "/" do
        :POST__root__
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

      get "render" do
        @instance_var = 'value'
        render('some/template')
      end

      redirect "/login", "new"

      redirect "foo", "/bar"
    end
  end

  def setup
    request = Harbor::Test::Request.new
    response = Harbor::Response.new(request)

    @example = Controllers::Foos.new(request, response)
    @router = Harbor::Router::instance
  end

  def test_redirect_to_relative_destination
    request = Harbor::Test::Request.new
    response = Harbor::Response.new(request)
    controller = Controllers::Foos.new(request, response)

    catch(:halt) do
      controller.send(:GET_login)
    end

    assert_equal 301, response.status
    assert_equal "/controller_test/foos/new", response.headers["Location"]
  end

  def test_redirect_from_relative_source
    request = Harbor::Test::Request.new
    response = Harbor::Response.new(request)
    controller = Controllers::Foos.new(request, response)

    catch(:halt) do
      controller.send(:GET_foo)
    end

    assert_equal 301, response.status
    assert_equal "/bar", response.headers["Location"]
  end

  def test_controller_is_available_through_config_container
    request = Harbor::Test::Request.new
    response = Harbor::Response.new(request)
    controller = config.get("ControllerTest::Controllers::Foos", request: request, response: response)
    assert_instance_of Controllers::Foos, controller
    assert_same request, controller.request
    assert_same response, controller.response
  end

  def test_generated_action_methods_return_expected_results
    assert_equal :GET__root__, @example.GET__root__
    assert_equal :POST__root__, @example.POST__root__
    assert_equal :GET, @example.GET
    assert_equal :GET_executive_report, @example.GET_executive_report
    assert_equal :GET__id, @example.GET__id
    assert_equal :GET__id_bars, @example.GET__id_bars
    assert_equal :GET__foo_id_bars__bar_id, @example.GET__foo_id_bars__bar_id
    assert_equal :GET_about_the_foos, @example.GET_about_the_foos
  end

  def test_generated_routes_match_actions
    assert_controller_route_matches("GET", "/", Controllers::Foos, :GET__root__)
    assert_controller_route_matches("POST", "/", Controllers::Foos, :POST__root__)
    assert_controller_route_matches("GET", "/controller_test/foos", Controllers::Foos, :GET)
    assert_controller_route_matches("GET", "/controller_test/foos/executive_report", Controllers::Foos, :GET_executive_report)
    assert_controller_route_matches("GET", "/controller_test/foos/42", Controllers::Foos, :GET__id)
    assert_controller_route_matches("GET", "/controller_test/foos/42/bars", Controllers::Foos, :GET__id_bars)
    assert_controller_route_matches("GET", "/controller_test/foos/42/bars/1337", Controllers::Foos, :GET__foo_id_bars__bar_id)
    assert_controller_route_matches("GET", "/about_the_foos", Controllers::Foos, :GET_about_the_foos)
  end

  def test_controller_becomes_view_context_when_shortcutted
    response = mock()
    controller = Controllers::Foos.new(nil, response)

    response.expects(:render).with('some/template', has_entry('instance_var' => 'value'))

    controller.GET_render
  end
end
