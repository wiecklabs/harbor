require "pathname"
require Pathname(__FILE__).dirname + "helper"

class ControllerRouterTest < Test::Unit::TestCase
  
  def test_path_matches
    router = Harbor::Controller::Router.new
    
    @short = false
    @parameterized = false
    @long = false
    
    router.register("/path/to/my", lambda { @short = true })
    router.match("/path/to/my")
    assert(@short)
    
    router.register("/path/to/my/action", lambda { @long = true })
    router.match("/path/to/my/action")
    assert(@long)
    
    router.register("/path/to/my/:id", lambda { @parameterized = true })
    router.match("/path/to/my/thing")
    assert(@parameterized)
  end
  
end