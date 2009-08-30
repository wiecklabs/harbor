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
  before :all do
    View::path.unshift Pathname(__FILE__).dirname + "views"
    View.layouts.default("layouts/application")
  end

  before do
    request_stub = Object.new
    class << request_stub
      def xhr?
        false
      end
    end

    @response = Response.new(request_stub)
  end

  after :all do
    View::path.clear
    View.layouts.clear
  end

  it "should buffer content" do
    @response.puts "Hello World"
    @response.print("Hello World\n")
    @response.buffer.to_a.should == (["Hello World\n"] * 2)
  end

  it "should have a default status of 200" do
    @response.status.should == 200
  end

  it "should have a default content_type of text/html" do
    @response.content_type.should == "text/html"
  end

  it "should generate basic headers automatically" do
    @response.print "Hello World"
    @response.headers.should == { "Content-Type" => "text/html", "Content-Length" => "Hello World".size.to_s }
  end

  describe "#render" do
    it "should render an html view" do
      @response.render "index", :text => "test"
      @response.buffer.should == "LAYOUT\ntest\n"
    end

    it "should render a view object" do
      @response.render XMLView.new("list")
      @response.buffer.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>Bob</name>\n</site>\n"
      @response.content_type.should == "text/xml"
    end
  end

end