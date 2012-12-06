#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::XMLView do

  before do
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"
  end
  
  after do
    Harbor::View::path.clear
  end

  it "must render" do
    view = Harbor::XMLView.new("list")
    view.to_s.must_equal "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>Bob</name>\n</site>\n"
  end

  it "must render with content" do
    view = Harbor::XMLView.new("show", :name => "John")
    view.to_s.must_equal "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>John</name>\n</site>\n"
  end

  it "must render a partial" do
    view = Harbor::XMLView.new("index")
    view.to_s.must_equal "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>John</name>\n  <name>James</name>\n</site>\n"
  end

  it "must render a template with an extension" do
    Harbor::XMLView.new("index.rxml").to_s.must_equal Harbor::XMLView.new("index").to_s
  end
end