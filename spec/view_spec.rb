require "pathname"
require Pathname(__FILE__).dirname + "helper"

describe "View" do
  before :all do
    View::path.unshift Pathname(__FILE__).dirname + "views"
  end

  after :all do
    View::path.clear
  end

  it "should render a view with variables" do
    view = View.new("index.html.erb", :text => "test")
    view.to_s.should == "test"
  end

  it "should render dependent views as defined in the view" do
    view = View.new("edit.html.erb")
    view.to_s.should == "EDIT PAGE\nFORM PARTIAL"
  end

  it "should render dependent views explicitly" do
    view = View.new("new.html.erb", :form => View.new("_form.html.erb"))
    view.to_s.should == "NEW PAGE\nFORM PARTIAL"
  end

  it "should render a layout" do
    view = View.new("edit.html.erb")
    view.to_s("layouts/application.html.erb").should == "LAYOUT\nEDIT PAGE\nFORM PARTIAL"
  end

end