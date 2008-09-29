require "pathname"
require Pathname(__FILE__).dirname + "helper"

class StubView
  def content_type
    "text/plain"
  end

  def to_s
    "Content"
  end
end

describe "Response" do
  before do
    @response = Response.new
  end

  it "should buffer content" do
    @response.puts "Hello World"
    @response << "Hello World\n"
    @response.write("Hello World\n")
    @response.string.to_a.should == ["Hello World\n"]*3
  end

  it "should have a default status of 200" do
    @response.status.should == 200
  end

  it "should have a default content_type of text/html" do
    @response.content_type.should == "text/html"
  end

  it "should generate basic headers automatically" do
    @response.write "Hello World"
    @response.headers.should == { "Content-Type" => "text/html", "Content-Length" => "Hello World".size.to_s }
  end

end