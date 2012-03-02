require_relative "helper"

class ViewTest < MiniTest::Unit::TestCase

  def setup
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"
  end

  def teardown
    Harbor::View::path.clear
    Harbor::View::engines.delete "str"
  end

  def test_view_exists
    assert Harbor::View.exists?("index.html.erb")
  end

  def test_view_doesnt_exist
    refute Harbor::View.exists?("somefilethatdoesnotexist")
  end

  def test_empty_view_path
    Harbor::View::path.clear
    refute Harbor::View.exists?("index.html.erb")
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

  def test_supports_engine_precedence
    Harbor::View::engines.unshift "str"
    view = Harbor::View.new("index", :text => "test")
    assert_equal("test from str", view.to_s.strip)
  end

  def test_supports_javascript_templates
    flunk
  end

  def test_supports_erubis_templates
    view = Harbor::View.new("erubis_test.erubis")
    assert_equal("Erubis::FastEruby", view.to_s)
  end
end
