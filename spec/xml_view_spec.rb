require "pathname"
require Pathname(__FILE__).dirname + "helper"

describe "XMLView" do
  before :all do
    View::path.unshift Pathname(__FILE__).dirname + "views"
  end

  after :all do
    View::path.clear
  end

  it "should render an XML view" do
    view = XMLView.new("list.rxml")
    view.to_s.should == "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>Bob</name>\n</site>\n"
  end
end