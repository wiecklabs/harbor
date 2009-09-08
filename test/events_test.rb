require "pathname"
require Pathname(__FILE__).dirname + "helper"

class EventsTest < Test::Unit::TestCase

  class Application
    include Harbor::Events
  end

  class Controller
    include Harbor::Events
  end

  def teardown
    Application.clear_events!
    Controller.clear_events!
  end

  def test_named_events_are_not_shared_across_classes
    raised_in_application = raised_in_controller = false
    Application.register_event(:event_one) { raised_in_application = true }
    Controller.register_event(:event_one) { raised_in_controller = true }

    application = Application.new
    application.raise_event(:event_one)

    assert raised_in_application == true
    assert raised_in_controller == false
  end

  def test_events_are_inherited
    not_found = false
    Application.register_event(:not_found) { not_found = true }

    my_application = Class.new(Application).new
    my_application.raise_event(:not_found)

    assert not_found = true
  end

end