require "pathname"
require Pathname(__FILE__).dirname + "helper"
require "ostruct"

class EmailAppenderTestTest < Test::Unit::TestCase
  
  class MockMailer
    attr_accessor :to, :from, :subject, :text, :html, :mail_server
    attr_accessor :last_delivery

    def send!
      @last_delivery = OpenStruct.new(:to => to, :from => from, :subject => subject, :text => text, :html => html)
    end
    
    def clear!
      @last_delivery = nil
    end
  end

  def setup
    @container = Harbor::Container.new
    @container.register(:mail_server, Harbor::MailServers::Sendmail.new)
    @mock_mailer = MockMailer.new
    @container.register(:mailer, @mock_mailer)
    @appender = Harbor::LogAppenders::Email.new(@container, "from@example.com", "to1@example.com", "to2@example.com")
  end
  
  def test_sends_error_email
    event = Logging::LogEvent.new(nil, 4, "Some error\nSome Details", false)
    @appender.write(event)
    
    assert_kind_of(OpenStruct, @mock_mailer.last_delivery)
    
    delivery = @mock_mailer.last_delivery
    assert_equal(["to1@example.com", "to2@example.com"], delivery.to)
    assert_equal("from@example.com", delivery.from)
    assert_equal("[ERROR] Some error", delivery.subject)
    assert(delivery.text["Some error\nSome Details"])
    assert_equal(nil, delivery.html)
  end
  
  def test_waits_for_threshold_before_sending_duplicate_email
    event = Logging::LogEvent.new(nil, 4, "Some error\nSome Details", false)

    @appender.write(event)
    assert_kind_of(OpenStruct, @mock_mailer.last_delivery)
    @mock_mailer.clear!
    
    @appender.write(event)
    assert_equal(nil, @mock_mailer.last_delivery)

    # One second before an email can be sent
    Time.warp(@appender.duplicate_subject_delivery_threshold - 1) do
      @appender.write(event)
      assert_equal(nil, @mock_mailer.last_delivery)
    end
    
    # Exactly when an email can be sent
    Time.warp(@appender.duplicate_subject_delivery_threshold) do
      @appender.write(event)
      assert_kind_of(OpenStruct, @mock_mailer.last_delivery)
      assert(@mock_mailer.last_delivery.text['Repeated 3 times since'])
      @mock_mailer.clear!
    end
  end
  
  def test_duplicate_emails_can_be_sent_after_threshold
    event = Logging::LogEvent.new(nil, 4, "Some error\nSome Details", false)

    @appender.write(event)
    assert_kind_of(OpenStruct, @mock_mailer.last_delivery)
    @mock_mailer.clear!
    
    Time.warp(@appender.duplicate_subject_delivery_threshold) do
      event = Logging::LogEvent.new(nil, 4, "Some OTHER error\nSome OTHER Details", false)
      @appender.write(event)
      assert_kind_of(OpenStruct, @mock_mailer.last_delivery)      
      
      @appender.write(event)
      assert_kind_of(OpenStruct, @mock_mailer.last_delivery)
      assert(!@mock_mailer.last_delivery.text['Repeated'])
      @mock_mailer.clear!
    end
    
  end
  
end
