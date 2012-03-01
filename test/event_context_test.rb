require_relative "helper"

class EventContextTest < MiniTest::Unit::TestCase

  def test_initialized_accessor_is_accessible
    context = Harbor::EventContext.new(:foo => 'bar')
    assert_equal 'bar', context.foo
  end

  def test_initialization_with_something_other_than_a_hash_raises_an_argument_error
    assert_raises ArgumentError do
      Harbor::EventContext.new(123)
    end
  end

  def test_missing_accessor_raises_no_method_error
    context = Harbor::EventContext.new
    assert_raises NoMethodError do
      context.foo
    end
  end

end
