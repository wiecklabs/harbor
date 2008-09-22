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
    view = View.new("index.html.erb")
    view.render(:text => "test").to_s.should == "test"
  end

  it "should render dependent views" do
    view = View.new("edit.html.erb", :form => "_form.html.erb")
    view.render.to_s.should == "EDIT PAGE\nFORM PARTIAL"
  end

end