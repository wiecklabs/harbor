module Wheels
  ##
  # Utility class for receiving email notifications of exceptions in
  # non-development environments.
  # 
  #   MyApplication.services.register("mailer", Wheels::Mailer)
  #   MyApplication.services.register("mail_server", Wheels::SendmailServer)
  #   
  #   require 'wheels/exception_notifier'
  #   Wheels::ExceptionNotifier.notification_address = "admin@site.com"
  # 
  # You will then receive email alerts for all 500 errors in the format of:
  # 
  #   From:     errors@request_host
  #   Subject:  [ERROR] [request_host] [environment] Exception description
  #   Body:     stack trace found in log, with request details.
  ##
  module ExceptionNotifier

    def self.notification_address=(address)
      @@notification_address = address
    end

    def self.notification_address
      @@notification_address
    rescue NameError
      raise "Wheels::ExceptionMailer.notification_address not set."
    end

    ##
    # 
    ##
    def handle_exception(exception, request, response)
      super

      return if environment == "development"

      mailer = self.class.services.get("mailer")
      mailer.to = Wheels::ExceptionNotifier.notification_address
      mailer.from = "errors@#{request.host}"

      subject = exception.to_s

      # We can't have multi-line subjects, so we chop off extra lines
      if subject[$/]
        subject = subject.split($/, 2)[0] + "..."
      end

      mailer.subject = "[ERROR] [#{request.host}] [#{environment}] #{subject}"
      mailer.text = build_exception_trace(exception, request)
      mailer.set_header("X-Priority", 1)
      mailer.set_header("X-MSMail-Priority", "High")
      mailer.send!
    end

  end
end

module Wheels
  class Cascade
    include Wheels::ExceptionMailer
  end

  class Application
    include Wheels::ExceptionMailer
  end
end