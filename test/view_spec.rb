#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::View do

  before do
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"
  end

  after do
    Harbor::View::path.clear
  end

  it "must render with variables" do
    Harbor::View.new("index", :text => "test").to_s.must_equal "test"
  end

  it "must render with partials" do
    Harbor::View.new("edit").to_s.must_equal "EDIT PAGE\nFORM PARTIAL"
  end

  it "must render an html file" do
    Harbor::View.new("index.html").to_s.must_equal "PLAIN HTML TEST\n"
  end

  it "must support passing a partial as a variable" do
    Harbor::View.new("new", :form => Harbor::View.new("_form")).to_s
      .must_equal "NEW PAGE\nFORM PARTIAL"
  end

  it "must render with a layout" do
    Harbor::View.new("edit").to_s("layouts/application")
      .must_equal "LAYOUT\nEDIT PAGE\nFORM PARTIAL"
  end

  it "must render with an extension" do
    Harbor::View.new("edit").to_s.must_equal Harbor::View.new("edit.html.erb").to_s
  end

  it "must return a plugin list" do
    Harbor::View::plugins("some/plugin/key").must_be_kind_of Harbor::PluginList
  end

  it "must trim leading slashes in plugin names" do
    Harbor::View::plugins("/some/plugin/key").must_equal Harbor::View::plugins("some/plugin/key")
  end

end