require_relative "helper"

class HooksTest < MiniTest::Unit::TestCase

  def setup
    @hooked_class = Class.new do
      class << self
        attr_accessor :existing_method_added_called
        def method_added(method)
          @existing_method_added_called = true
        end
      end

      include Harbor::Hooks

      attr_accessor :before_hook_calls, :after_hook_calls, :hooked_method_calls
      attr_accessor :before_hook_with_args_calls, :after_hook_with_args_calls, :hooked_method_with_args_calls
      attr_accessor :before_hook_with_block_calls, :after_hook_with_block_calls, :hooked_method_with_block_calls
      attr_accessor :before_hook_with_method_added_calls, :hooked_method_with_method_added_calls

      def initialize
        @before_hook_calls = 0
        @after_hook_calls = 0
        @hooked_method_calls = 0

        @before_hook_with_args_calls = 0
        @after_hook_with_args_calls = 0
        @hooked_method_with_args_calls = 0

        @before_hook_with_block_calls = 0
        @after_hook_with_block_calls = 0
        @hooked_method_with_block_calls = 0

        @before_hook_with_method_added_calls = 0
        @hooked_method_with_method_added_calls = 0
      end

      def hooked_method
        @hooked_method_calls += 1
      end

      before :hooked_method do |reciever|
        reciever.before_hook_calls += 1
      end

      after :hooked_method do |reciever|
        reciever.after_hook_calls += 1
      end

      def hooked_method_with_args(color, size)
        @hooked_method_with_args_calls += 1
      end

      before :hooked_method_with_args do |reciever|
        reciever.before_hook_with_args_calls += 1
      end

      after :hooked_method_with_args do |reciever|
        reciever.after_hook_with_args_calls += 1
      end

      def hooked_method_with_block(color, size, &block)
        yield
        @hooked_method_with_block_calls += 1
      end

      before :hooked_method_with_block do |reciever|
        reciever.before_hook_with_block_calls += 1
      end

      after :hooked_method_with_block do |reciever|
        reciever.after_hook_with_block_calls += 1
      end

      before :hooked_method_with_method_added do |reciever|
        reciever.before_hook_with_method_added_calls += 1
      end

      def hooked_method_with_method_added
        @hooked_method_with_method_added_calls += 1
      end

      before :hooked_method_with_throw_halt do |reciever|
        throw :halt, true
      end

      def hooked_method_with_throw_halt
        false
      end

    end
  end

  def test_before_hooks_register_class_method
    assert_respond_to(@hooked_class, :before)
  end

  def test_before_and_after_hook_firing
    hooked_instance = @hooked_class.new

    assert_equal(0, hooked_instance.before_hook_calls)
    assert_equal(0, hooked_instance.hooked_method_calls)
    assert_equal(0, hooked_instance.after_hook_calls)

    hooked_instance.hooked_method

    assert_equal(1, hooked_instance.before_hook_calls)
    assert_equal(1, hooked_instance.hooked_method_calls)
    assert_equal(1, hooked_instance.after_hook_calls)
  end

  def test_after_hooks_register_class_method
    assert_respond_to(@hooked_class, :after)
  end

  def test_method_added_respects_existing_method_added
    assert(@hooked_class.existing_method_added_called)
  end

  def test_can_define_hooks_before_method_added
    hooked_instance = @hooked_class.new

    assert_equal(0, hooked_instance.before_hook_with_method_added_calls)
    assert_equal(0, hooked_instance.hooked_method_with_method_added_calls)

    hooked_instance.hooked_method_with_method_added

    assert_equal(1, hooked_instance.before_hook_with_method_added_calls)
    assert_equal(1, hooked_instance.hooked_method_with_method_added_calls)
  end

  def test_hooked_methods_should_preserve_arguments
    hooked_instance = @hooked_class.new

    assert_equal(0, hooked_instance.before_hook_with_args_calls)
    assert_equal(0, hooked_instance.hooked_method_with_args_calls)
    assert_equal(0, hooked_instance.after_hook_with_args_calls)

    hooked_instance.hooked_method_with_args("blue", 10)

    assert_equal(1, hooked_instance.before_hook_with_args_calls)
    assert_equal(1, hooked_instance.hooked_method_with_args_calls)
    assert_equal(1, hooked_instance.after_hook_with_args_calls)
  end

  def test_hooked_methods_should_preserve_block_arguments
    hooked_instance = @hooked_class.new

    assert_equal(0, hooked_instance.before_hook_with_block_calls)
    assert_equal(0, hooked_instance.hooked_method_with_block_calls)
    assert_equal(0, hooked_instance.after_hook_with_block_calls)

    @block_called = 0

    hooked_instance.hooked_method_with_block("blue", 10) do
      @block_called += 1
    end

    assert_equal(1, @block_called)

    assert_equal(1, hooked_instance.before_hook_with_block_calls)
    assert_equal(1, hooked_instance.hooked_method_with_block_calls)
    assert_equal(1, hooked_instance.after_hook_with_block_calls)
  end

  def test_hooks_are_run_when_hooked_method_is_redefined
    @hooked_class.class_eval do
      def hooked_method
        @hooked_method_calls = 2
      end
    end

    hooked_instance = @hooked_class.new

    assert_equal(0, hooked_instance.before_hook_calls)
    assert_equal(0, hooked_instance.hooked_method_calls)
    assert_equal(0, hooked_instance.after_hook_calls)

    hooked_instance.hooked_method

    assert_equal(1, hooked_instance.before_hook_calls)
    assert_equal(2, hooked_instance.hooked_method_calls)
    assert_equal(1, hooked_instance.after_hook_calls)
  end

  def test_hooks_are_run_when_class_is_subclassed
    subclass = Class.new(@hooked_class)

    hooked_instance = subclass.new

    assert_equal(0, hooked_instance.before_hook_calls)
    assert_equal(0, hooked_instance.hooked_method_calls)
    assert_equal(0, hooked_instance.after_hook_calls)

    hooked_instance.hooked_method

    assert_equal(1, hooked_instance.before_hook_calls)
    assert_equal(1, hooked_instance.hooked_method_calls)
    assert_equal(1, hooked_instance.after_hook_calls)
  end

  def test_hooks_are_additive_in_subclass
    subclass = Class.new(@hooked_class) do
      before(:hooked_method) { |receiver| receiver.before_hook_calls += 1 }
    end

    hooked_instance = subclass.new

    assert_equal(0, hooked_instance.before_hook_calls)
    assert_equal(0, hooked_instance.hooked_method_calls)
    assert_equal(0, hooked_instance.after_hook_calls)

    hooked_instance.hooked_method

    assert_equal(2, hooked_instance.before_hook_calls)
    assert_equal(1, hooked_instance.hooked_method_calls)
    assert_equal(1, hooked_instance.after_hook_calls)
  end

  def test_hooks_are_clearable
    @hooked_class.hooks[:hooked_method].clear!
    hooked_instance = @hooked_class.new

    assert_equal(0, hooked_instance.before_hook_calls)
    assert_equal(0, hooked_instance.hooked_method_calls)
    assert_equal(0, hooked_instance.after_hook_calls)

    hooked_instance.hooked_method

    assert_equal(0, hooked_instance.before_hook_calls)
    assert_equal(1, hooked_instance.hooked_method_calls)
    assert_equal(0, hooked_instance.after_hook_calls)
  end

  def test_hooks_are_clearble_from_subclass
    subclass = Class.new(@hooked_class) do
      hooks[:hooked_method].clear!
      before(:hooked_method) { |receiver| receiver.before_hook_calls += 1 }
    end

    hooked_instance = subclass.new

    assert_equal(0, hooked_instance.before_hook_calls)
    assert_equal(0, hooked_instance.hooked_method_calls)
    assert_equal(0, hooked_instance.after_hook_calls)

    hooked_instance.hooked_method

    assert_equal(1, hooked_instance.before_hook_calls)
    assert_equal(1, hooked_instance.hooked_method_calls)
    assert_equal(0, hooked_instance.after_hook_calls)
  end

  def test_throw_halt_is_caught_and_returned
    hooked_instance = @hooked_class.new

    result = hooked_instance.hooked_method_with_throw_halt

    assert(result)

  end

end
