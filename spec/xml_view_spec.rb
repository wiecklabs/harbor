require "pathname"
require Pathname(__FILE__).dirname + "helper"

describe "XMLView" do
  before :all do
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"
  end

  after :all do
    Harbor::View::path.clear
  end

  it "should render an XML view" do
    view = Harbor::XMLView.new("list")
    view.to_s.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>Bob</name>\n</site>\n"
  end

  it "should render an xml view with a context" do
    view = Harbor::XMLView.new("show", :name => "John")
    view.to_s.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>John</name>\n</site>\n"
  end

  it "should render an xml partial" do
    view = Harbor::XMLView.new("index")
    view.to_s.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>John</name>\n  <name>James</name>\n</site>\n"
  end

  it "should render a file with an extension" do
    Harbor::XMLView.new("index.rxml").to_s.should == Harbor::XMLView.new("index").to_s
  end
end