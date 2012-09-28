require "pathname"
require Pathname(__FILE__).dirname + "helper"

class RouterTest < Test::Unit::TestCase

  include Harbor

  def setup
    setup_browser!
  end
  
  def test_initializer
    assert_equal([], Router.new.routes)
    
    router = Router.new do
      get("/") {}
    end
    
    # get() now creates a route for get and head methods
    assert_equal(2, router.routes.size)
  end

  def test_registering_a_route_adds_matchers_and_handlers
    @router.register :get, lambda { |request| request.path_info == "/" } do
      "Hello"
    end

    assert_equal(1, @router.routes.size)    
  end
  
  def test_request_should_match_route_defined_with_regular_expression
    @router.register(:get, /^\/users$/) { |request, response| response.print "Index" }
    browser.get("/users")
    assert_equal("Index", browser.last_response.body)
  end
  
  def test_regex_routes_should_mutate_request_route_captures  
    @router.register(:get, /^\/users\/(\d*)\/posts\/(\d*)$/) { |request, response| response.print request.route_captures.inspect  }
    browser.get("/users/1234/posts/4321")
    assert_equal(["1234", "4321"].inspect, browser.last_response.body)
  end

  def test_request_should_match_route_defined_with_a_normal_string    
    @router.register(:get, "/users") { |request, response| response.print "Index" }
    browser.get("/users")
    assert_equal("Index", browser.last_response.body)
  end
  
  def test_request_should_match_string_route_defined_with_named_parameters  
    @router.register(:get, "/:slug") do |request, response|
      assert(request.params.has_key?("slug"))
      assert_equal("this-is-a-slug", request.params["slug"])
      response.print "Index"
    end
    browser.get("/this-is-a-slug")
    assert_equal("Index", browser.last_response.body)
  end
  
  def test_route_define_with_get_only_matches_GET
    @router.get("/") { |request, response| response.print "Index" }

    browser.get("/")
    assert(browser.last_response.ok?)
    
    browser.put("/")
    assert(!browser.last_response.ok?)
    
    browser.post("/")
    assert(!browser.last_response.ok?)
    
    browser.delete("/")
    assert(!browser.last_response.ok?)
  end
  
  def test_route_define_with_put_only_matches_PUT
    @router.put("/") { |request, response| response.print "Index" }
  
    browser.post("/", { "_method" => "put" })
    assert(browser.last_response.ok?)
    
    browser.put("/")
    assert(browser.last_response.ok?)
    
    browser.get("/")
    assert(!browser.last_response.ok?)
    
    browser.post("/")
    assert(!browser.last_response.ok?)
    
    browser.delete("/")
    assert(!browser.last_response.ok?)
  end
  
  def test_route_define_with_post_only_matches_POST
    @router.post("/") { |request, response| response.print "Index" }
    
    browser.post("/")
    assert(browser.last_response.ok?)
    
    browser.get("/")
    assert(!browser.last_response.ok?)
    
    browser.put("/")
    assert(!browser.last_response.ok?)
    
    browser.delete("/")
    assert(!browser.last_response.ok?)
  end
  
  def test_route_define_with_delete_only_matches_DELETE
    @router.delete("/") { |request, response| response.print "Index" }

    browser.post("/", { "_method" => "delete" })
    assert(browser.last_response.ok?)
    
    browser.delete("/")
    assert(browser.last_response.ok?)
    
    browser.get("/")
    assert(!browser.last_response.ok?)
    
    browser.post("/")
    assert(!browser.last_response.ok?)
    
    browser.put("/")
    assert(!browser.last_response.ok?)
  end
  
  class SampleController
    attr_accessor :request, :response
    
    def index
      response.print "Index"
    end
  end
  
  def test_using_passes_controller_to_the_block  
    @router.using(@container, SampleController) do
      get("/") { |controller| controller.index }
    end
  
    browser.get("/")
    assert_equal("Index", browser.last_response.body)
  end
  
  def test_using_passes_request_as_an_optional_second_argument
    @router.using(@container, SampleController) do
      get("/") { |controller, params| controller.index }
    end
    
    browser.get("/")
    assert_equal("Index", browser.last_response.body)
  end
  
  def test_using_can_use_service_names_instead_of_classes
    @container.register("sample_controller", SampleController)
  
    @router.using(@container, "sample_controller") do
      get("/") { |controller| controller.index }
    end
    
    browser.get("/")
    assert_equal("Index", browser.last_response.body)
  end
  
end
