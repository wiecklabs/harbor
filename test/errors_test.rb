require_relative "helper"

class ErrorsTest < MiniTest::Unit::TestCase

  def test_errors
    errors = Harbor::Errors.new
    errors << "Error 1"

    assert_equal(1, errors.size)
  end

  def test_errors_unrolls_enumerables
    errors = Harbor::Errors.new
    messages = ["Error 1", "Error 2", "Error 3"]
    errors << messages

    assert_equal(3, errors.size)
  end

  def test_errors_collection_can_be_combined
    errors = Harbor::Errors.new(['Error 1']) + Harbor::Errors.new(['Error 2'])

    assert_equal(2, errors.size)
  end

end
