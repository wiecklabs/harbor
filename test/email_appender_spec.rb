#!/usr/bin/env jruby

require_relative "helper"
require "harbor/logging/appenders/email"
require "ostruct"

describe Harbor::LogAppenders::Email do

  before do
    @container = Harbor::Container.new

    mail_server = Class.new(Harbor::MailServers::Abstract) do
      attr_accessor :last_delivery

      def deliver(message)
        @last_delivery = message
      end

      def clear!
        @last_delivery = nil
      end
    end

    @mail_server = mail_server.new
    @container.register(:mail_server, @mail_server)
    @container.register(:mailer, Harbor::Mailer)
    @appender = Harbor::LogAppenders::Email.new(@container, "from@example.com", "to1@example.com", "to2@example.com")
    @appender.level = 3 # :error
  end

  it "does not send email when event is below severity threshold" do
    assert_email_is_not_sent(1)
    assert_email_is_not_sent(2)
  end

  it "sends email when event is at or above severity threshold" do
    assert_email_is_sent(3)
    assert_email_is_sent(4)
    assert_email_is_sent(5)
  end

  it "waits for threshold before sending duplicate email" do
    event = Logging::LogEvent.new(nil, 4, "Some error\nSome Details", false)

    @appender.write(event)
    @mail_server.last_delivery.wont_be_nil
    @mail_server.clear!

    @appender.write(event)
    @mail_server.last_delivery.must_be_nil

    # One second before an email can be sent
    Time.warp(@appender.duplicate_subject_delivery_threshold - 1) do
      @appender.write(event)
      @mail_server.last_delivery.must_be_nil
    end

    # Exactly when an email can be sent
    Time.warp(@appender.duplicate_subject_delivery_threshold) do
      @appender.write(event)
      @mail_server.last_delivery.wont_be_nil
      @mail_server.last_delivery.text["Repeated 3 times since"].wont_be_nil
      @mail_server.clear!
    end
  end

  it "will send duplicate emails after threshold" do
    event = Logging::LogEvent.new(nil, 4, "Some error\nSome Details", false)

    @appender.write(event)
    @mail_server.last_delivery.wont_be_nil
    @mail_server.clear!

    Time.warp(@appender.duplicate_subject_delivery_threshold) do
      event = Logging::LogEvent.new(nil, 4, "Some OTHER error\nSome OTHER Details", false)
      @appender.write(event)
      @mail_server.last_delivery.wont_be_nil

      @appender.write(event)
      @mail_server.last_delivery.wont_be_nil
      @mail_server.last_delivery.text["Repeated"].must_be_nil
      @mail_server.clear!
    end

  end

  private

  def assert_email_is_not_sent(severity)
    event = Logging::LogEvent.new(nil, severity, "Some error\nSome Details", false)
    @appender.write(event)

    assert_nil(@mail_server.last_delivery)
  end

  def assert_email_is_sent(severity)
    event = Logging::LogEvent.new(nil, severity, "Some error\nSome Details", false)
    @appender.write(event)

    assert(@mail_server.last_delivery)

    delivery = @mail_server.last_delivery
    assert_equal(["to1@example.com", "to2@example.com"], delivery.to)
    assert_equal("from@example.com", delivery.from)
    assert_equal("[ERROR] [#{`hostname`.strip}] Some error", delivery.subject)
    assert(delivery.text["Some error\nSome Details"])
    assert_equal(nil, delivery.html)
  end

end
