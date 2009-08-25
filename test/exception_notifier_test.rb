require "pathname"
require Pathname(__FILE__).dirname + "helper"
require "harbor/exception_notifier"

class ExceptionNotifierTest < Test::Unit::TestCase

  class MockMailServer < Harbor::MailServers::Abstract

    def mailings
      @mailings ||= []
    end

    def deliver(mail)
      mailings << mail
    end
  end

  def setup
    @services = Harbor::Container.new
    @services.register("mail_server", MockMailServer.new)
    @services.register("mailer", Harbor::Mailer)

    Harbor::ExceptionNotifier.notification_address = "errors@site.com"

    @request_log = StringIO.new
    @error_log = StringIO.new

    logger = Logging::Logger['request']
    logger.clear_appenders
    logger.add_appenders Logging::Appenders::IO.new('request', @request_log)

    logger = Logging::Logger['error']
    logger.clear_appenders
    logger.add_appenders Logging::Appenders::IO.new('error', @error_log)

    @application = Class.new(Harbor::Application) do
      def self.routes(services)
        Harbor::Router.new do
          get("/") { raise "Error" }
        end
      end
    end
  end

  def teardown
    Harbor::Application.events.clear
  end

  def test_uses_default_behavior_in_development
    app = @application.new(@services, "development")
    rack_errors = StringIO.new
    app.call({
      "PATH_INFO" => "/",
      "REQUEST_METHOD" => "GET",
      "rack.errors" => rack_errors,
      "HTTP_HOST" => "",
      "rack.request.form_hash" => {}
    })

    assert_equal(0, @services.get("mail_server").mailings.size)
  end

  def test_sends_email_in_non_development_mode
    app = @application.new(@services, "production")
    rack_errors = StringIO.new
    app.call({
      "PATH_INFO" => "/",
      "REQUEST_METHOD" => "GET",
      "rack.errors" => rack_errors,
      "HTTP_HOST" => "",
      "rack.request.form_hash" => {}
    })

    mailings = @services.get("mail_server").mailings
    assert_equal(1, mailings.size)
  end
end