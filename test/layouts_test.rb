require_relative "helper"

class LayoutsTest < MiniTest::Unit::TestCase
  def test_layouts_sort_properly
    layouts = Harbor::Layouts.new

    fragments = [
      ["*", "application"],
      ["admin/*", "admin"],
      ["admin/videos/show", "videos_show"],
      ["admin/*/show", "show"]
    ]

    fragments.size.times do
      layouts.clear

      fragments.push(fragments.shift)
      fragments.each { |fragment| layouts.map(*fragment) }

      map = layouts.instance_variable_get(:@map)

      assert_equal %r{^admin/videos/show}, map[0][0]
      assert_equal %r{^admin/.*/show}, map[1][0]
      assert_equal %r{^admin/.*}, map[2][0]
      assert_equal %r{^.*}, map[3][0]
    end
  end

  def test_clear_empties_map
    layouts = Harbor::Layouts.new
    map = layouts.instance_variable_get(:@map)

    layouts.map("admin/*", "layouts/admin")
    layouts.default("layouts/application")

    assert_equal 1, map.size
    assert_equal "layouts/application", layouts.instance_variable_get(:@default)

    layouts.clear

    assert_equal 0, map.size
    assert_equal "layouts/application", layouts.instance_variable_get(:@default)
  end

  def test_match
    layouts = Harbor::Layouts.new

    fragments = [
      ["admin/*", "admin"],
      ["admin/videos/show", "videos_show"],
      ["admin/*/show", "show"]
    ]

    fragments.each { |fragment| layouts.map(*fragment) }

    assert_equal "admin", layouts.match("admin/photos/new")
    assert_equal "videos_show", layouts.match("admin/videos/show")
    assert_equal "show", layouts.match("admin/photos/show")
    assert_equal "layouts/application", layouts.match("photos/index")

    layouts.default("application")

    assert_equal "application", layouts.match("photos/index")
  end
end
