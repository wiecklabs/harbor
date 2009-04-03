require "pathname"
require Pathname(__FILE__).dirname + "helper"
require "wheels/exception_notifier"

class ExceptionNotifierTest < Test::Unit::TestCase

  class MockMailServer < Wheels::MailServers::Abstract

    def mailings
      @mailings ||= []
    end

    def deliver(mail)
      mailings << mail
    end
  end

  def setup
    @services = Wheels::Container.new
    @services.register("mail_server", MockMailServer.new)
    @services.register("mailer", Wheels::Mailer)

    Wheels::ExceptionNotifier.notification_address = "errors@site.com"
    Wheels::Application.error_handlers << Wheels::ExceptionNotifier

    @request_log = StringIO.new
    @error_log = StringIO.new

    logger = Logging::Logger['request']
    logger.clear_appenders
    logger.add_appenders Logging::Appenders::IO.new('request', @request_log)

    logger = Logging::Logger['error']
    logger.clear_appenders
    logger.add_appenders Logging::Appenders::IO.new('error', @error_log)

    @application = Class.new(Wheels::Application) do
      def self.routes(services)
        Wheels::Router.new do
          get("/") { raise "Error" }
        end
      end
    end
  end

  def teardown
    Wheels::Application.error_handlers.clear
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