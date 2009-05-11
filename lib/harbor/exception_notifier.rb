module Harbor
  ##
  # Utility class for receiving email notifications of exceptions in
  # non-development environments.
  # 
  #   services.register("mailer", Harbor::Mailer)
  #   services.register("mail_server", Harbor::SendmailServer)
  #   
  #   require 'harbor/exception_notifier'
  #   Harbor::ExceptionNotifier.notification_address = "admin@site.com"
  #   Harbor::Application.error_handlers << Harbor::ExceptionNotifier
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
      raise "Harbor::ExceptionMailer.notification_address not set."
    end

    def self.call(exception, request, response, trace)
      return if request.environment == "development"

      mailer = request.application.services.get("mailer")
      mailer.to = notification_address

      host = request.env["HTTP_X_FORWARDED_HOST"] || request.host
      mailer.from = "errors@#{host}"

      subject = exception.to_s

      # We can't have multi-line subjects, so we chop off extra lines
      if subject[$/]
        subject = subject.split($/, 2)[0] + "..."
      end

      mailer.subject = "[ERROR] [#{request.host}] [#{request.environment}] #{subject}"
      mailer.text = trace
      mailer.set_header("X-Priority", 1)
      mailer.set_header("X-MSMail-Priority", "High")
      mailer.send!
    end

  end
end