require_relative 'helper'

class XmlViewTestTest < MiniTest::Unit::TestCase

  def setup
    Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"
  end

  def teardown
    Harbor::View::path.clear
  end

  def test_rendering_an_xml_view
    view = Harbor::XMLView.new("list")
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>Bob</name>\n</site>\n", view.to_s)
  end

  def test_rendering_an_xml_view_with_a_context
    view = Harbor::XMLView.new("show", :name => "John")
    assert_equal("<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>John</name>\n</site>\n", view.to_s)
  end

  def test_rendering_an_xml_partial
    view = Harbor::XMLView.new("index")
    assert_equal(view.to_s, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<site>\n  <name>John</name>\n  <name>James</name>\n</site>\n")
  end

  def test_rendering_a_file_with_an_extension
    assert_equal(Harbor::XMLView.new("index.rxml").to_s, Harbor::XMLView.new("index").to_s)
  end
end
