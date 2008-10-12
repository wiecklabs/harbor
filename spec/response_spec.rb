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
    @response = Response.new({})
    View::path.unshift Pathname(__FILE__).dirname + "views"
  end

  after :all do
    View::path.clear
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

  describe "#render" do
    it "should render an html view" do
      @response.render "index.html.erb", :text => "test"
      @response.string.should == "LAYOUT\ntest\n"
    end

    it "should render a view object" do
      @response.render XMLView.new("list.rxml")
      @response.string.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>Bob</name>\n</site>\n"
      @response.content_type.should == "text/xml"
    end
  end

end