require "pathname"
require Pathname(__FILE__).dirname + "helper"

describe "Application" do
  before do
    router = Router.new do
      get("/") { |request, response| response << "Hello World" }
      get("/error") { raise }
    end
    @application = Application.new(router)
  end

  it "should return an array for Rack" do
    result = @application.call({ "PATH_INFO" => "/", "REQUEST_METHOD" => "GET" })
    result[0].should == 200
    result[1].should == { "Content-Type" => "text/html", "Content-Length" => "Hello World".size.to_s }
    result[2].should == ["Hello World"]
  end

  it "should return a 404 for non-existent routes" do
    result = @application.call({ "PATH_INFO" => "/doesnt-exist", "REQUEST_METHOD" => "GET" })
    result[0].should == 404
  end

  it "should return a 500 if an error occurs in the handler" do
    result = @application.call({ "PATH_INFO" => "/error", "REQUEST_METHOD" => "GET" })
    result[0].should == 500
  end

end