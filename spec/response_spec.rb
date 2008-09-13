require "pathname"
require Pathname(__FILE__).dirname + "helper"

class StubApplication
end

describe "Response" do
  before do
    application = StubApplication.new
    @response = Response.new(application)
  end

  it "should accept an application object on initialize" do
    application = StubApplication.new
    Response.new(application).application.should == application
  end

  it "should buffer content" do
    @response.puts "Hello World"
    @response << "Hello World\n"
    @response.write("Hello World\n")
    @response.rewind
    @response.readlines.should == ["Hello World\n"]*3
  end

  it "should have a default status of 200" do
    @response.status.should == 200
  end

  it "should have a default content_type of text/html" do
    @response.content_type.should == "text/html"
  end

  it "should generate basic headers automatically" do
    @response.write "Hello World"
    @response.rewind
    @response.headers.should == { "Content-Type" => "text/html", "Content-Length" => "Hello World".size.to_s }
  end

end