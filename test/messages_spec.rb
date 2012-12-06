#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::Messages do

  it "must be empty" do
    Harbor::Messages.new(nil).must_be_empty
  end

  it "must be equal to a Hash of the same values" do
    Harbor::Messages.new(error: "Error").must_equal error: "Error"
  end

  it "must be able to access an expired collection" do
    messages = Harbor::Messages.new(:error => "Error")
    messages[:error]
    messages.must_be :expired
  end

  it "must be provided by a Session" do
    response = Harbor::Test::Response.new
    request = Harbor::Test::Request.new
    response.request = request
    request.session = Harbor::Test::Session.new

    response.message(:error, "Error")
    request.session[:messages].must_equal error: "Error"
  end

end