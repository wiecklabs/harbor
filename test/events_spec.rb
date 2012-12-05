#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::Events do

  class Application
    include Harbor::Events
  end

  class Controller
    include Harbor::Events
  end

  class Handler

    class << self

      attr_accessor :called

      def called?
        @called
      end

    end

    def initialize(event)
      Handler.called = false
    end

    def call
      Handler.called = true
    end

  end

  class HandlerOne

    class << self

      attr_accessor :called

      def called?
        @called
      end

    end

    def initialize(event)
      HandlerOne.called = false
    end

    def call
      HandlerOne.called = true
    end

  end

  class HandlerTwo

    class << self

      attr_accessor :called

      def called?
        @called
      end

    end

    def initialize(event)
      HandlerTwo.called = false
    end

    def call
      HandlerTwo.called = true
    end

  end

  class ContextualHandler

    class << self

      attr_accessor :called

      def called?
        @called
      end

    end

    def initialize(event)
      @event = event
    end

    def call
      @event.foo
      ContextualHandler.called = true
    end

  end

  after do
    Application.clear_event_handlers!
    Controller.clear_event_handlers!
  end

  it "must call handlers" do
    Application.register_event_handler(:foo, Handler)
    Application.new.raise_event2(:foo, nil)

    Handler.must_be :called
  end

  it "must call handlers with arguments" do
    Application.register_event_handler(:foo, HandlerOne)
    Application.new.raise_event2(:foo, nil)

    HandlerOne.must_be :called
  end

  it "must normalize strings" do
    raised = false
    Application.register_event_handler('foo') { raised = true }
    Application.new.raise_event2(:foo, nil)

    raised.must_equal true
  end

  it "must normalize symbols" do
    raised = false
    Application.register_event_handler(:foo) { raised = true }
    Application.new.raise_event2('foo', nil)

    raised.must_equal true
  end

  it "must clear events" do
    Application.events['foo'].must_be_nil

    Application.register_event_handler('foo') { 1 + 1 }

    Application.events["foo"].size.must_equal 1

    Application.clear_event_handlers!

    Application.events["foo"].must_be_nil
  end

  it "must inherit events" do
    not_found = false
    Application.register_event_handler(:not_found) { |event| not_found = true }

    my_application = Class.new(Application).new
    my_application.raise_event2(:not_found, nil)

    not_found.must_equal true
  end

  it "must not share named events among classes not in the same type-hierarchy" do
    raised_in_application = raised_in_controller = false
    Application.register_event_handler(:event_one) { raised_in_application = true }
    Controller.register_event_handler(:event_one) { raised_in_controller = true }

    application = Application.new
    application.raise_event2(:event_one, nil)

    raised_in_application.must_equal true
    raised_in_controller.must_equal false
  end

  it "must fail if a block is passed" do
    -> do
      Application.register_event_handler(:foo, Handler) { 1 + 1 }
    end.must_raise RuntimeError
  end

  it "requires a class be registered" do
    -> do
      Application.register_event_handler(:foo, 321)
    end.must_raise RuntimeError
  end

  it "requires a Handler" do
    -> do
      Application.register_event_handler(:foo)
    end.must_raise RuntimeError
  end

end
