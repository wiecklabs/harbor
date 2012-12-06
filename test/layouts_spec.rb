#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::Layouts do

  it "must sort properly" do
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

      map[0][0].must_equal %r{^admin/videos/show}
      map[1][0].must_equal %r{^admin/.*/show}
      map[2][0].must_equal %r{^admin/.*}
      map[3][0].must_equal %r{^.*}
    end
  end

  it "must empty map on clear" do
    layouts = Harbor::Layouts.new
    map = layouts.instance_variable_get(:@map)

    layouts.map("admin/*", "layouts/admin")
    layouts.default("layouts/application")

    map.size.must_equal 1
    layouts.instance_variable_get(:@default).must_equal "layouts/application"

    layouts.clear

    map.size.must_equal 0
    layouts.instance_variable_get(:@default).must_equal "layouts/application"
  end

  it "must match" do
    layouts = Harbor::Layouts.new

    fragments = [
      ["admin/*", "admin"],
      ["admin/videos/show", "videos_show"],
      ["admin/*/show", "show"]
    ]

    fragments.each { |fragment| layouts.map(*fragment) }


    layouts.match("admin/photos/new").must_equal "admin"
    layouts.match("admin/videos/show").must_equal "videos_show"
    layouts.match("admin/photos/show").must_equal "show"
    layouts.match("photos/index").must_equal "layouts/application"

    layouts.default("application")

    layouts.match("photos/index").must_equal "application"
  end
end