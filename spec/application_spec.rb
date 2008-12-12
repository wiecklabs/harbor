require "pathname"
require Pathname(__FILE__).dirname + "helper"

describe "Application" do
  before do
    router = Router.new do
      get("/") { |request, response| response.puts "Hello World" }
      get("/error") { raise }
    end
    @application = Application.new(router)
  end

  it "should default to a development environment" do
    @application.environment.should == "development"
  end
  
  it "should return an array for Rack" do
    result = @application.call({ "PATH_INFO" => "/", "REQUEST_METHOD" => "GET" })
    result[0].should == 200
    result[1].should == { "Content-Type" => "text/html", "Content-Length" => ("Hello World".size + 1).to_s }
    result[2].should == "Hello World\n"
  end

  it "should return a 404 for non-existent routes" do
    result = @application.call({ "PATH_INFO" => "/doesnt-exist", "REQUEST_METHOD" => "GET" })
    result[0].should == 404
  end

end