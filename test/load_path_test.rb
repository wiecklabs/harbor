require_relative "helper"

class LoadPathTest < MiniTest::Unit::TestCase

  # Adding non-strings (pathnames for example) breaks bundle exec.
  def test_load_path_contains_only_strings
    assert_equal [String], $:.map { |path| path.class }.uniq
  end

end
