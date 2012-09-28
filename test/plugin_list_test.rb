require_relative 'helper'

class PluginListTest < MiniTest::Unit::TestCase

  class TestPlugin < Harbor::Plugin
    attr_accessor :plugin_type

    def to_s
      "Fancy #{@plugin_type}Plugin"
    end
  end

  def setup
    @map = Harbor::PluginList.new
  end

  def test_appending_a_plugin
    @map << TestPlugin
    @map << "Sample String Plugin"

    assert_equal(2, @map.size)
  end

  def test_clearing_plugins
    @map << TestPlugin
    @map << "Sample String Plugin"
    @map.clear

    assert_equal(0, @map.size)
  end

end
