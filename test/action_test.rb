require_relative "helper"

class ActionTest < MiniTest::Unit::TestCase

  module Controllers
    class Foos < Harbor::Controller

      attr_accessor :bar
      
      # /foos
      get do
        @bar
      end

    end
  end

  def test_action_initializes_controller_through_container
    config.set("bar", true)
    
    request = Harbor::Test::Request.new
    response = Harbor::Response.new(request)
    action = Harbor::Controller::Action.new(Controllers::Foos, :GET)
    
    assert action.call(request, response)
  end
end
