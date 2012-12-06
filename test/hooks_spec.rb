#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::Hooks do

  before do
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

  it "has a before hook" do
    @hooked_class.must_respond_to :before
  end

  it "must fire before and after hooks" do
    hooked_instance = @hooked_class.new

    hooked_instance.before_hook_calls.must_equal 0
    hooked_instance.hooked_method_calls.must_equal 0
    hooked_instance.after_hook_calls.must_equal 0

    hooked_instance.hooked_method

    hooked_instance.before_hook_calls.must_equal 1
    hooked_instance.hooked_method_calls.must_equal 1
    hooked_instance.after_hook_calls.must_equal 1
  end

  it "has an after hook" do
    @hooked_class.must_respond_to :after
  end

  it "must chain standard method_added hook, preserving it's functionality" do
    @hooked_class.existing_method_added_called.must_equal true
  end

  it "can define hooks before method added" do
    hooked_instance = @hooked_class.new

    hooked_instance.before_hook_with_method_added_calls.must_equal 0
    hooked_instance.hooked_method_with_method_added_calls.must_equal 0

    hooked_instance.hooked_method_with_method_added

    hooked_instance.before_hook_with_method_added_calls.must_equal 1
    hooked_instance.hooked_method_with_method_added_calls.must_equal 1
  end

  it "must preserve arguments of hooked methods" do
    hooked_instance = @hooked_class.new

    hooked_instance.before_hook_with_args_calls.must_equal 0
    hooked_instance.hooked_method_with_args_calls.must_equal 0
    hooked_instance.after_hook_with_args_calls.must_equal 0

    hooked_instance.hooked_method_with_args("blue", 10)

    hooked_instance.before_hook_with_args_calls.must_equal 1
    hooked_instance.hooked_method_with_args_calls.must_equal 1
    hooked_instance.after_hook_with_args_calls.must_equal 1
  end

  it "must preserve block arguments of hooked methods" do
    hooked_instance = @hooked_class.new

    hooked_instance.before_hook_with_block_calls.must_equal 0
    hooked_instance.hooked_method_with_block_calls.must_equal 0
    hooked_instance.after_hook_with_block_calls.must_equal 0

    @block_called = 0

    -> do
      hooked_instance.hooked_method_with_block("blue", 10) do
        @block_called += 1
      end
    end.wont_raise

    @block_called.must_equal 1

    hooked_instance.before_hook_with_block_calls.must_equal 1
    hooked_instance.hooked_method_with_block_calls.must_equal 1
    hooked_instance.after_hook_with_block_calls.must_equal 1
  end

  it "runs hooks even if hooked method is later redefined" do
    @hooked_class.class_eval do
      def hooked_method
        @hooked_method_calls = 2
      end
    end

    hooked_instance = @hooked_class.new

    hooked_instance.before_hook_calls.must_equal 0
    hooked_instance.hooked_method_calls.must_equal 0
    hooked_instance.after_hook_calls.must_equal 0

    hooked_instance.hooked_method

    hooked_instance.before_hook_calls.must_equal 1
    hooked_instance.hooked_method_calls.must_equal 2
    hooked_instance.after_hook_calls.must_equal 1
  end

  it "must pass hooks to decendents" do
    subclass = Class.new(@hooked_class)

    hooked_instance = subclass.new

    hooked_instance.before_hook_calls.must_equal 0
    hooked_instance.hooked_method_calls.must_equal 0
    hooked_instance.after_hook_calls.must_equal 0

    hooked_instance.hooked_method

    hooked_instance.before_hook_calls.must_equal 1
    hooked_instance.hooked_method_calls.must_equal 1
    hooked_instance.after_hook_calls.must_equal 1
  end

  it "hooks must be additive in subclasses" do
    subclass = Class.new(@hooked_class) do
      before(:hooked_method) { |receiver| receiver.before_hook_calls += 1 }
    end

    hooked_instance = subclass.new

    hooked_instance.before_hook_calls.must_equal 0
    hooked_instance.hooked_method_calls.must_equal 0
    hooked_instance.after_hook_calls.must_equal 0

    hooked_instance.hooked_method

    hooked_instance.before_hook_calls.must_equal 2
    hooked_instance.hooked_method_calls.must_equal 1
    hooked_instance.after_hook_calls.must_equal 1
  end

  it "must be possible to clear hooks" do
    @hooked_class.hooks[:hooked_method].clear!
    hooked_instance = @hooked_class.new

    hooked_instance.before_hook_calls.must_equal 0
    hooked_instance.hooked_method_calls.must_equal 0
    hooked_instance.after_hook_calls.must_equal 0

    hooked_instance.hooked_method

    hooked_instance.before_hook_calls.must_equal 0
    hooked_instance.hooked_method_calls.must_equal 1
    hooked_instance.after_hook_calls.must_equal 0
  end

  it "must be possible to clear inherited hooks" do
    subclass = Class.new(@hooked_class) do
      hooks[:hooked_method].clear!
      before(:hooked_method) { |receiver| receiver.before_hook_calls += 1 }
    end

    hooked_instance = subclass.new

    hooked_instance.before_hook_calls.must_equal 0
    hooked_instance.hooked_method_calls.must_equal 0
    hooked_instance.after_hook_calls.must_equal 0

    hooked_instance.hooked_method

    hooked_instance.before_hook_calls.must_equal 1
    hooked_instance.hooked_method_calls.must_equal 1
    hooked_instance.after_hook_calls.must_equal 0
  end

  it "must catch :halt and return" do
    hooked_instance = @hooked_class.new

    result = nil
    -> do
      result = hooked_instance.hooked_method_with_throw_halt
    end.wont_raise

    result.wont_be_nil
  end

end
