require_relative "helper"
require "harbor/exception_notifier"

class ExceptionNotifierTest < MiniTest::Unit::TestCase

  class MockMailServer < Harbor::Mail::Servers::Abstract

    def mailings
      @mailings ||= []
    end

    def deliver(mail)
      mailings << mail
    end
  end

  def setup
    @services = Harbor::Container.new
    @services.set("mail_server", MockMailServer.new)
    @services.set("mailer", Harbor::Mail::Mailer)

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
    flunk "Old, incompatible w/ propposed Harbor::Router and Harbor::Application"

    app = @application.new(@services, "development")
    rack_errors = StringIO.new
    app.call({
      "PATH_INFO" => "/",
      "REQUEST_METHOD" => "GET",
      "rack.errors" => rack_errors,
      "HTTP_HOST" => "",
      "rack.request.form_hash" => {},
      "rack.input" => ""
    })

    assert_equal(0, @services.get("mail_server").mailings.size)
  end
end
