require "pathname"
require Pathname(__FILE__).dirname + "helper"

describe "Router" do

  describe "#initialize" do
    it "should set @routes to []" do
      Router.new.routes.should == []
    end

    it "should accept a block of routes" do
      router = Router.new do
        get("/") {}
      end
      router.routes.size.should == 1
    end
  end

  describe "#register" do
    before :all do
      @router = Router.new
    end

    it "should add matchers and handlers to @routes" do
      @router.register :get, lambda { |request| request.path_info == "/" } do
        "Hello"
      end
      @router.routes.size.should == 1
    end
  end

  describe "#transform" do
    before do
      @router = Router.new
      @request = Rack::Request.new("PATH_INFO" => "/users", "REQUEST_METHOD" => "GET")
    end

    describe "with a proc" do
      it "should do nothing" do
        @router.register(:get, lambda { |r| r.path_info == "/users" }) { "Index" }
        @router.match(@request).call.should == "Index"
      end
    end

    describe "with a regular expression" do
      it "should match the expression on request.path_info" do
        @router.register(:get, /^\/users$/) { "Index" }
        @router.match(@request).call.should == "Index"
      end
    end

    describe "with a string" do
      it "should match normal strings" do
        @router.register(:get, "/users") { "Index" }
        @router.match(@request).call.should == "Index"
      end

      it "should strings with named paramaters" do
        @router.register(:get, "/:controller") { "Index" }
        @router.match(@request).call.should == "Index"
      end

      it "should update the request params" do
        @router.register(:get, "/:controller") { "Index" }
        @router.match(@request)
        @request.params.should include("controller")
        @request.params["controller"].should == "users"
      end
    end

  end

  describe "#get" do
    before do
      @router = Router.new
      @router.get("/") { "Index" }
      @request = Rack::Request.new("PATH_INFO" => "/")
    end

    it "should match a get request" do
      @request.env["REQUEST_METHOD"] = "GET"
      @router.match(@request).call.should == "Index"
    end

    it "should not match a post request" do
      @request.env["REQUEST_METHOD"] = "POST"
      @router.match(@request).should be_false
    end
  end

  describe "#post" do
    before do
      @router = Router.new
      @router.post("/") { "Index" }
      @request = Rack::Request.new("PATH_INFO" => "/")
    end

    it "should match a post request" do
      @request.env["REQUEST_METHOD"] = "POST"
      @router.match(@request).call.should == "Index"
    end

    it "should not match a get request" do
      @request.env["REQUEST_METHOD"] = "GET"
      @router.match(@request).should be_false
    end
  end

  describe "#put" do
    before do
      @router = Router.new
      @router.put("/") { "Index" }
      @request = Rack::Request.new("PATH_INFO" => "/")
    end

    it "should match a put request" do
      @request.env["REQUEST_METHOD"] = "PUT"
      @router.match(@request).call.should == "Index"
    end

    it "should match a put request (with _method)" do
      @request.env["REQUEST_METHOD"] = "POST"
      @request.params.update("_method" => "put")
      @router.match(@request).call.should == "Index"
    end

    it "should not match a post request" do
      @request.env["REQUEST_METHOD"] = "POST"
      @router.match(@request).should be_false
    end
  end

  describe "#delete" do
    before do
      @router = Router.new
      @router.delete("/") { "Index" }
      @request = Rack::Request.new("PATH_INFO" => "/")
    end

    it "should match a delete request" do
      @request.env["REQUEST_METHOD"] = "DELETE"
      @router.match(@request).call.should == "Index"
    end

    it "should match a delete request (with _method)" do
      @request.env["REQUEST_METHOD"] = "POST"
      @request.params.update("_method" => "delete")
      @router.match(@request).call.should == "Index"
    end

    it "should not match a post request" do
      @request.env["REQUEST_METHOD"] = "POST"
      @router.match(@request).should be_false
    end
  end

end