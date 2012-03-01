require_relative 'helper'

class TextHelperTest < MiniTest::Unit::TestCase

  class TextHelper
    include Harbor::ViewContext::Helpers::Text
  end

  def setup
    @helper = TextHelper.new
    @value = <<-EOS.strip.split.map { |line| line.strip }.join(" ")
      Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod
      tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam,
      quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo
      consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse
      cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat
      non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.
    EOS
  end

  # truncate(value, character_count = 30, trailing = "&hellip;")
  def test_truncate_at_defaults
    assert_equal(@value[0, 29] + "&hellip;", @helper.truncate(@value))
  end

  def test_truncate_at_20_characters
    assert_equal(@value[0, 19] + "&hellip;", @helper.truncate(@value, 20))
  end

  def test_truncate_at_50_characters_and_three_periods
    assert_equal(@value[0, 47] + "...", @helper.truncate(@value, 50, "..."))
  end

  def test_truncate_no_op
    assert_equal(@value, @helper.truncate(@value, 500))
    assert_equal(@value, @helper.truncate(@value, 500, "..."))
  end

  def test_arbitrary_objects
    user = Class.new do
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def to_s
        @name
      end
    end

    bob = user.new("Bob is a really cool guy who is always on time, unlike Mike who is a slacker.")

    assert_equal("Bob is a really", @helper.truncate(bob, 15, ""))
  end

  def test_truncate_blank_values
    # Empty or Nil input should not error.
    assert_equal("", @helper.truncate(""))

    assert_equal("", @helper.truncate(nil))
  end

  def test_truncate_errors
    assert_raises(ArgumentError) do
      # character_count should be a non-zero number.
      assert_equal("", @helper.truncate("...", 0))
    end

    assert_raises(ArgumentError) do
      # character_count should be non-nil.
      assert_equal("", @helper.truncate("", nil))
    end
  end

  # truncate_on_words(value, character_count = 30, trailing = "&hellip;")
  def test_truncate_on_words_at_defaults
    # closest end-of-word match to 30 is 26
    assert_equal(@value[0, 26] + "&hellip;", @helper.truncate_on_words(@value))
  end

  def test_truncate_on_words_round_up
    assert_equal(@value[0, 51] + "&hellip;", @helper.truncate_on_words(@value, 50))
  end

  def test_truncate_on_words_round_down
    assert_equal(@value[0, 17] + "&hellip;", @helper.truncate_on_words(@value, 20))
  end

  def test_truncate_on_words_custom_trailing
    assert_equal(@value[0, 17] + "...", @helper.truncate_on_words(@value, 20, "..."))
  end

  def test_truncate_on_words_arbitrary_objects
    user = Class.new do
      attr_reader :name

      def initialize(name)
        @name = name
      end

      def to_s
        @name
      end
    end

    bob = user.new("Bob is a really cool guy who is always on time, unlike Mike who is a slacker.")

    assert_equal("Bob is a really", @helper.truncate_on_words(bob, 15, ""))
  end

  def test_truncate_on_words_no_op
    assert_equal(@value, @helper.truncate_on_words(@value, 500))
    assert_equal(@value, @helper.truncate_on_words(@value, 500, "..."))
  end

  def test_truncate_on_words_errors
    assert_raises(ArgumentError) do
      # character_count should be a non-zero number.
      assert_equal("", @helper.truncate_on_words("...", 0))
    end

    assert_raises(ArgumentError) do
      # character_count should be non-nil.
      assert_equal("", @helper.truncate_on_words("", nil))
    end
  end

  def test_truncate_on_words_blank_values
    # Empty or Nil input should not error.
    assert_equal("", @helper.truncate_on_words(""))
    assert_equal("", @helper.truncate_on_words(nil))
  end

end
