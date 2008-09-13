require "rubygems"
require "spec"
require "pathname"
require "rack/request"
require Pathname(__FILE__).dirname.parent + "lib/router"

module Rack
  class Request
    def params
      @params ||= {}
    end
  end
end

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

  describe "#transform" do
    before do
      @router = Router.new
      @request = Rack::Request.new("PATH_INFO" => "/users", "REQUEST_METHOD" => "GET")
    end

    describe "with a proc" do
      it "should do nothing" do
        @router.register(:get, lambda { |r| r.path_info == "/users" }) { "Root" }
        @router.match(@request).call.should == "Root"
      end
    end

    describe "with a regular expression" do
      it "should match the expression on request.path_info" do
        @router.register(:get, /^\/users$/) { "Root" }
        @router.match(@request).call.should == "Root"
      end
    end

    describe "with a string" do
      it "should transform it to a regular expression" do
        @router.register(:get, "/:controller") { "Root" }
        @router.match(@request).call.should == "Root"
      end

      it "should update the request params" do
        @router.register(:get, "/:controller") { "Root" }
        @router.match(@request)
        @request.params.should include("controller")
        @request.params["controller"].should == "users"
      end
    end

  end

end