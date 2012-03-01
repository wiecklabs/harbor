require_relative 'helper'

class MessagesTest < MiniTest::Unit::TestCase

  def test_messages_with_nil
    assert_equal({}, Harbor::Messages.new(nil))
  end

  def test_messages_with_params
    assert_equal({ :error => "Error" }, Harbor::Messages.new(:error => "Error"))
  end

  def test_access_expires_messages
    messages = Harbor::Messages.new(:error => "Error")
    messages[:error]
    assert messages.expired?
  end

  def test_request_messages_with_session
    response = Harbor::Test::Response.new
    request = Harbor::Test::Request.new
    response.request = request
    request.session = Harbor::Test::Session.new

    response.message("error", "Error")
    assert_equal({"error" => "Error"}, request.session[:messages])
  end

end
