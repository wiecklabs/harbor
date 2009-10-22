require "pathname"
require Pathname(__FILE__).dirname + "helper"

class MessagesTest < Test::Unit::TestCase

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

  def test_request_messages_without_session
    request = Harbor::Test::Request.new
    assert_equal({}, request.messages)

    request = Harbor::Test::Request.new
    request.params["messages"] = { "error" => "Error" }
    assert_equal({"error" => "Error"}, request.messages)
    assert_equal "Error", request.message("error")
  end

  def test_response_message_without_session
    response = Harbor::Test::Response.new
    request = Harbor::Test::Request.new
    response.request = request

    response.message("error", "Error")
    assert_equal({"error" => "Error"}, request.params["messages"])
    assert_equal("Error", request.message("error"))
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