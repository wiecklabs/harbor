require_relative "helper"

class EventsTest < MiniTest::Unit::TestCase

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

  def teardown
    Application.clear_event_handlers!
    Controller.clear_event_handlers!
  end

  def test_classy_event_handlers_with_zero_arguments
    Application.register_event_handler(:foo, Handler)

    Application.new.raise_event(:foo, nil)

    assert_equal true, Handler.called?
  end

  def test_classy_event_handlers_with_one_argument
    Application.register_event_handler(:foo, HandlerOne)

    Application.new.raise_event(:foo, nil)

    assert_equal true, HandlerOne.called?
  end

  def test_event_named_by_string_can_be_handled_by_symbol
    raised = false
    Application.register_event_handler('foo') { raised = true }

    Application.new.raise_event(:foo, nil)

    assert_equal true, raised
  end

  def test_event_named_by_symbol_can_be_handled_by_string
    raised = false
    Application.register_event_handler(:foo) { raised = true }

    Application.new.raise_event('foo', nil)

    assert_equal true, raised
  end

  def test_events_can_be_cleared
    assert_nil Application.events['foo']

    Application.register_event_handler('foo') { 1 + 1 }

    assert_equal 1, Application.events['foo'].size

    Application.clear_event_handlers!

    assert_nil Application.events['foo']
  end

  def test_events_are_inherited
    not_found = false
    Application.register_event_handler(:not_found) { |event| not_found = true }

    my_application = Class.new(Application).new
    my_application.raise_event(:not_found, nil)

    assert_equal true, not_found
  end

  def test_named_events_are_not_shared_across_classes
    raised_in_application = raised_in_controller = false
    Application.register_event_handler(:event_one) { raised_in_application = true }
    Controller.register_event_handler(:event_one) { raised_in_controller = true }

    application = Application.new
    application.raise_event(:event_one, nil)

    assert_equal true, raised_in_application
    assert_equal false, raised_in_controller
  end

  def test_registering_a_class_and_a_block_fails
    assert_raises RuntimeError do
      Application.register_event_handler(:foo, Handler) { 1 + 1 }
    end
  end

  def test_registering_something_other_than_a_class_or_block_fails
    assert_raises RuntimeError do
      Application.register_event_handler(:foo, 321)
    end
  end

  def test_registering_without_a_class_or_a_block_fails
    assert_raises RuntimeError do
      Application.register_event_handler(:foo)
    end
  end

end
