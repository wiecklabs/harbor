require File.expand_path(File.dirname(__FILE__) + "/../helper")

module Support
  class ArrayTest < MiniTest::Unit::TestCase

    def test_compress_with_empty_array
      assert_equal [[], []], [].compress
    end

    def test_compress_with_single_element_array
      assert_equal [[], [1]], [1].compress
    end

    def test_compress_with_two_non_sequential_items
      assert_equal [[], [1, 3]], [1, 3].compress
    end

    def test_compress_with_two_sequential_items
      assert_equal [[1..2], []], [1, 2].compress
    end

    def test_compress_with_multiple_non_sequential_items
      assert_equal [[], [1, 3, 5, 7]], [1, 3, 5, 7].compress
    end

    def test_compress_with_multiple_sequential_items
      assert_equal [[1..4], []], [1, 2, 3, 4].compress
    end

    def test_compress_with_sequential_and_non_sequential_items
      assert_equal [[1..4], [6, 8]], [1, 2, 3, 4, 6, 8].compress
    end

  end
end
