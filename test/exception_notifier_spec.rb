#!/usr/bin/env jruby

require_relative "helper"
require "harbor/exception_notifier"

describe Harbor::ExceptionNotifier do

  class MockMailServer < Harbor::MailServers::Abstract

    def mailings
      @mailings ||= []
    end

    def deliver(mail)
      mailings << mail
    end
  end

  before do
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

  after do
    Harbor::Application.events.clear
  end

  it "must suppress emails in development" do
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

    @services.get("mail_server").mailings.size.must_equal 0
  end

  it "must send email in production" do
    app = @application.new(@services, "production")
    rack_errors = StringIO.new
    app.call({
      "PATH_INFO" => "/",
      "REQUEST_METHOD" => "GET",
      "rack.errors" => rack_errors,
      "HTTP_HOST" => "",
      "rack.request.form_hash" => {}
    })

    @services.get("mail_server").mailings.size.must_equal 1
  end
end