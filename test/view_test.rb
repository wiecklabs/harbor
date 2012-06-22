require_relative "helper"

class ViewTest < MiniTest::Unit::TestCase
  def setup
    Harbor::View::paths.unshift Pathname(__FILE__).dirname + "fixtures/views"
  end

  def teardown
    Harbor::View::paths.clear
  end

  def test_render_with_variables
    view = Harbor::View.new("index", :text => "test")
    assert_equal("test", view.to_s)
  end

  def test_render_with_partials
    view = Harbor::View.new("edit")
    assert_equal("EDIT PAGE\nFORM PARTIAL", view.to_s)
  end

  def test_passing_a_partial_as_a_variable
    view = Harbor::View.new("new", :form => Harbor::View.new("_form"))
    assert_equal("NEW PAGE\nFORM PARTIAL", view.to_s)
  end

  def test_render_with_layout
    view = Harbor::View.new("edit")
    assert_equal("LAYOUT\nEDIT PAGE\nFORM PARTIAL", view.to_s("layouts/application"))
  end

  def test_render_with_extension
    assert_equal(Harbor::View.new("edit").to_s, Harbor::View.new("edit.html.erb").to_s)
  end

  def test_plugins_returns_a_plugin_list
    assert_kind_of(Harbor::PluginList, Harbor::View::plugins("some/plugin/key"))
  end

  def test_leading_slashes_in_plugin_names_are_trimmed
    assert_equal(Harbor::View::plugins("/some/plugin/key"), Harbor::View::plugins("some/plugin/key"))
  end

  def test_supports_multiple_engines
    view = Harbor::View.new("index_str", :text => "test")
    assert_equal("test from str", view.to_s.strip)
  end

  def test_loads_erubis_if_available
    view = Harbor::View.new("erubis_test.html.erubis")
    assert_equal("Erubis::FastEruby", view.to_s)
  end

  def test_supports_partials_for_formats_other_than_html
    view = Harbor::View.new("index.xml")
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n<name>John</name>\n<name>James</name>\n</site>\n", view.to_s)
  end
end
