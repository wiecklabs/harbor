require_relative "helper"
require "ostruct"

class EmailAppenderTestTest < MiniTest::Unit::TestCase

  def setup
    @container = Harbor::Container.new

    mail_server = Class.new(Harbor::Mail::Servers::Abstract) do
      attr_accessor :last_delivery

      def deliver(message)
        @last_delivery = message
      end

      def clear!
        @last_delivery = nil
      end
    end

    @mail_server = mail_server.new
    @container.set(:mail_server, @mail_server)
    @container.set(:mailer, Harbor::Mail::Mailer)
    @appender = Harbor::LogAppenders::Email.new(@container, "from@example.com", "to1@example.com", "to2@example.com")
    @appender.level = 3 # :error
  end

  def test_does_not_send_email_when_event_is_below_severity_threshold
    assert_email_is_not_sent(1)
    assert_email_is_not_sent(2)
  end

  def test_sends_email_when_event_is_at_or_above_severity_threshold
    assert_email_is_sent(3)
    assert_email_is_sent(4)
    assert_email_is_sent(5)
  end

  def test_waits_for_threshold_before_sending_duplicate_email
    event = Logging::LogEvent.new(nil, 4, "Some error\nSome Details", false)

    @appender.write(event)
    assert(@mail_server.last_delivery)
    @mail_server.clear!

    @appender.write(event)
    assert_equal(nil, @mail_server.last_delivery)

    # One second before an email can be sent
    Time.warp(@appender.duplicate_subject_delivery_threshold - 1) do
      @appender.write(event)
      assert_equal(nil, @mail_server.last_delivery)
    end

    # Exactly when an email can be sent
    Time.warp(@appender.duplicate_subject_delivery_threshold) do
      @appender.write(event)
      assert(@mail_server.last_delivery)
      assert(@mail_server.last_delivery.text['Repeated 3 times since'])
      @mail_server.clear!
    end
  end

  def test_duplicate_emails_can_be_sent_after_threshold
    event = Logging::LogEvent.new(nil, 4, "Some error\nSome Details", false)

    @appender.write(event)
    assert(@mail_server.last_delivery)
    @mail_server.clear!

    Time.warp(@appender.duplicate_subject_delivery_threshold) do
      event = Logging::LogEvent.new(nil, 4, "Some OTHER error\nSome OTHER Details", false)
      @appender.write(event)
      assert(@mail_server.last_delivery)

      @appender.write(event)
      assert(@mail_server.last_delivery)
      assert(!@mail_server.last_delivery.text['Repeated'])
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
