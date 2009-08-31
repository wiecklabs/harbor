require "pathname"
require Pathname(__FILE__).dirname + "helper"

class ViewTest < Test::Unit::TestCase
  
  def setup
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"
  end

  def teardown
    Harbor::View::path.clear
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

end