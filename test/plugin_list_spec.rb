#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::PluginList do
  
  class TestPlugin < Harbor::Plugin
    attr_accessor :plugin_type

    def to_s
      "Fancy #{@plugin_type}Plugin"
    end
  end
  
  before do
    @map = Harbor::PluginList.new
  end

  it "must append" do
    @map << TestPlugin
    @map << "Sample String Plugin"

    @map.size.must_equal 2
  end

  it "must clear" do
    @map << TestPlugin
    @map << "Sample String Plugin"
    @map.clear

    @map.must_be_empty
  end
  
end