require "pathname"
require Pathname(__FILE__).dirname + "helper"

class RouterTest < Test::Unit::TestCase

  include Harbor
  
  def setup
    @application = Class.new(Harbor::Application)
    @router = Router.new
  end

  def test_initializer
    assert_equal([], Router.new.routes)
    
    router = Router.new do
      get("/") {}
    end
    
    assert_equal(1, router.routes.size)
  end

  def test_registering_a_route_adds_matchers_and_handlers
    @router.register :get, lambda { |request| request.path_info == "/" } do
      "Hello"
    end

    assert_equal(1, @router.routes.size)    
  end
  
  def test_request_should_match_route_defined_with_regular_expression
    request = Harbor::Request.new(@application, "PATH_INFO" => "/users", "REQUEST_METHOD" => "GET")

    @router.register(:get, /^\/users$/) { "Index" }
    assert_equal("Index", @router.match(request).call)
  end

  def test_request_should_match_route_defined_with_a_normal_string
    request = Harbor::Request.new(@application, "PATH_INFO" => "/users", "REQUEST_METHOD" => "GET")
    
    @router.register(:get, "/users") { "Index" }
    assert_equal("Index", @router.match(request).call)
  end

  def test_request_should_match_string_route_defined_with_named_parameters
    request = Harbor::Request.new(@application, "PATH_INFO" => "/this-is-a-slug", "REQUEST_METHOD" => "GET")

    @router.register(:get, "/:slug") { "Index" }
    assert_equal("Index", @router.match(request).call)
    assert(request.params.has_key?("slug"))
    assert_equal("this-is-a-slug", request.params["slug"])
  end
  
  def test_route_define_with_get_only_matches_GET
    @router.get("/") { "Index" }
    request = Harbor::Request.new(@application, "PATH_INFO" => "/")
    
    request.env["REQUEST_METHOD"] = "GET"
    assert(@router.match(request))

    request.env["REQUEST_METHOD"] = "PUT"
    assert(!@router.match(request))

    request.env["REQUEST_METHOD"] = "POST"
    assert(!@router.match(request))

    request.env["REQUEST_METHOD"] = "DELETE"
    assert(!@router.match(request))
  end

  def test_route_define_with_put_only_matches_PUT
    @router.put("/") { "Index" }
    request = Harbor::Request.new(@application, "PATH_INFO" => "/")

    request.env["REQUEST_METHOD"] = "PUT"
    assert(@router.match(request))
    
    request.env["REQUEST_METHOD"] = "POST"
    request.env["rack.request.form_hash"] = { "_method" => "put" }
    assert(@router.match(request))
    request.env["rack.request.form_hash"] = nil

    request.env["REQUEST_METHOD"] = "GET"
    assert(!@router.match(request))

    request.env["REQUEST_METHOD"] = "POST"
    assert(!@router.match(request))

    request.env["REQUEST_METHOD"] = "DELETE"
    assert(!@router.match(request))
  end

  def test_route_define_with_post_only_matches_POST
    @router.post("/") { "Index" }
    request = Harbor::Request.new(@application, "PATH_INFO" => "/")

    request.env["REQUEST_METHOD"] = "POST"
    assert(@router.match(request))

    request.env["REQUEST_METHOD"] = "GET"
    assert(!@router.match(request))

    request.env["REQUEST_METHOD"] = "PUT"
    assert(!@router.match(request))

    request.env["REQUEST_METHOD"] = "DELETE"
    assert(!@router.match(request))
  end
  
  def test_route_define_with_delete_only_matches_DELETE
    @router.delete("/") { "Index" }
    request = Harbor::Request.new(@application, "PATH_INFO" => "/")

    request.env["REQUEST_METHOD"] = "DELETE"
    assert(@router.match(request))
    
    request.env["REQUEST_METHOD"] = "POST"
    request.env["rack.request.form_hash"] = { "_method" => "delete" }
    assert(@router.match(request))
    request.env["rack.request.form_hash"] = nil

    request.env["REQUEST_METHOD"] = "GET"
    assert(!@router.match(request))

    request.env["REQUEST_METHOD"] = "PUT"
    assert(!@router.match(request))

    request.env["REQUEST_METHOD"] = "POST"
    assert(!@router.match(request))
  end
  
  class SampleController
    attr_accessor :request, :response
  end
  
  def test_using_passes_controller_to_the_block
    request = Harbor::Request.new(@application, "PATH_INFO" => "/", "REQUEST_METHOD" => "GET")
    @container = Container.new

    @router.using(@container, SampleController) do
      get("/") { |controller| controller }
    end

    assert_kind_of(SampleController, @router.match(request).call(request, nil))
  end
  
  def test_using_passes_request_as_an_optional_second_argument
    request = Harbor::Request.new(@application, "PATH_INFO" => "/", "REQUEST_METHOD" => "GET")
    @container = Container.new

    @router.using(@container, SampleController) do
      get("/") { |controller, request| request }
    end
    
    assert_equal(request, @router.match(request).call(request, nil))
  end
  
  def test_using_can_use_service_names_instead_of_classes
    request = Harbor::Request.new(@application, "PATH_INFO" => "/", "REQUEST_METHOD" => "GET")
    @container = Container.new
    @container.register("sample_controller", SampleController)

    @router.using(@container, "sample_controller") do
      get("/") { |controller, request| request }
    end
    
    assert_equal(request, @router.match(request).call(request, nil))    
  end

end