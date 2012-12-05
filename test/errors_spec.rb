#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::Errors do

  it "must behave like a collection" do
    errors = Harbor::Errors.new
    errors << "Error 1"

    errors.size.must_equal 1
  end

  it "must flatten enumerables" do
    errors = Harbor::Errors.new
    messages = ["Error 1", "Error 2", "Error 3"]
    errors << messages

    errors.size.must_equal 3
  end

  it "must support concatenation" do
    errors = Harbor::Errors.new(['Error 1']) + Harbor::Errors.new(['Error 2'])

    errors.size.must_equal 2
  end

end