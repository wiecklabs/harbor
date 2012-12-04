#!/usr/bin/env jruby

require "pathname"
require Pathname(__FILE__).dirname + "helper"

describe Harbor::Configuration do

  config.load!(Pathname(__FILE__).dirname.parent + "env")

  it "must define a global config method" do
    config.must_be_kind_of Harbor::Configuration
  end

  it "must disable debug mode by default" do
    config.debug?.must_equal false
  end

  it "must default the locale to english" do
    config.locales.default.must_equal Harbor::Locale["en-US"]
  end

  it "must provide a default cache" do
    config.cache.must_be_kind_of Harbor::Cache
  end

  it "must provide a hostname" do
    config.hostname.must_equal `hostname`.strip
  end

  it "must_allow you to set arbitrary properties" do
    config.test_setter = true
    config.test_setter.must_equal true
  end

  it "must allow you to re-register services" do
    config.reregistered = false
    config.reregistered = true

    config.reregistered.must_equal true
  end
end