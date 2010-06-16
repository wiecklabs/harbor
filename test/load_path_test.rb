require "pathname"
require Pathname(__FILE__).dirname + "helper"

class LoadPathTest < Test::Unit::TestCase

  # Adding non-strings (pathnames for example) breaks bundle exec.
  def test_load_path_contains_only_strings
    assert_equal [String], $:.map(&:class).uniq
  end

end
