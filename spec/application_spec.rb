require "pathname"
require Pathname(__FILE__).dirname + "helper"

describe "Application" do
  before :all do
    View::path.unshift Pathname(__FILE__).dirname + "views"
  end

  after :all do
    View::path.clear
  end
  
  before do
    router = Router.new do
      get("/") { |request, response| response.puts "Hello World" }
      get("/error") { raise }
      get("/hello_view") { |request, response| response.render("hello_view", :name => "Sam", :layout => nil) }
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
  
  it "should render a View" do
    result = @application.call({ "PATH_INFO" => "/hello_view", "REQUEST_METHOD" => "GET" })
    result[0].should == 200
    result[1].should == { "Content-Type" => "text/html", "Content-Length" => "Hello Sam!\n".size.to_s }
    result[2].should == "Hello Sam!\n"
  end

end