#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::EventContext do

  it "must make initialization parameters accessible as getters" do
    context = Harbor::EventContext.new(:foo => 'bar')
    context.foo.must_equal "bar"
  end

  it "must require a Hash for initialization when parameters are used" do
    -> { Harbor::EventContext.new(123) }.must_raise ArgumentError
  end

  it "must raise a NoMethodError when uninitialized getters are called" do
    context = Harbor::EventContext.new
    -> { context.foo }.must_raise NoMethodError
  end

end
