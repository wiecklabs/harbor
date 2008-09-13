require "rubygems"
require "spec"
require "pathname"
require "rack/request"
require Pathname(__FILE__).dirname.parent + "lib/router"

describe "Router" do

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

  describe "#match" do
    before :all do
      @router = Router.new
      @router.register :get, lambda { |request| request.path_info == "/users/show" } do
        "User"
      end
    end

    it "should match the correct route" do
      request = Rack::Request.new("PATH_INFO" => "/users/show", "REQUEST_METHOD" => "GET")
      @router.match(request).call.should == "User"
    end

  end

  describe "#get" do
    before :all do
      @router = Router.new
      @request = Rack::Request.new("PATH_INFO" => "/users/show", "REQUEST_METHOD" => "GET")
    end

    it "should transform a regex to a block" do
      @router.get(/\/users\/.*/) { "User" }
      @router.match(@request).call.should == "User"
    end
  end

end