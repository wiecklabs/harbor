require "pathname"
require Pathname(__FILE__).dirname + "helper"

class EventsTest < Test::Unit::TestCase

  class Application
    include Harbor::Events
  end

  class Controller
    include Harbor::Events
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

end

