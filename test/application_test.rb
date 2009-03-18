require "helper"

class ApplicationTest < Test::Unit::TestCase

  def setup
    @router = Wheels::Router.new do
      get("/") {}
      post("/") {}
    end
  end

  def default_test
  end

end