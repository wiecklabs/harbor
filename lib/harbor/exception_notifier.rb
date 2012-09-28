class Harbor
  ##
  # Utility class for receiving email notifications of exceptions in
  # non-development environments.
  #
  #   services.register("mailer", Harbor::Mailer)
  #   services.register("mail_server", Harbor::SendmailServer)
  #
  #   require 'harbor/exception_notifier'
  #
  # You will then receive email alerts for all 500 errors in the format of:
  #
  #   From:     errors@request_host
  #   Subject:  [ERROR] [request_host] [environment] Exception description
  #   Body:     stack trace found in log, with request details.
  ##
  class ExceptionNotifier

    def self.notification_address=(address)
      @@notification_address = address
    end

    def self.notification_address
      @@notification_address
    rescue NameError
      raise "Harbor::ExceptionMailer.notification_address not set."
    end

    def self.notification_address?
      defined?(@@notification_address)
    end

    def self.notify(exception, request, response, trace)
      return if config.development?

      mailer = config.get("mailer")
      mailer.to = notification_address

      host = request.env["HTTP_X_FORWARDED_HOST"] || request.host
      mailer.from = "errors@#{host}"

      subject = exception.to_s

      # We can't have multi-line subjects, so we chop off extra lines
      if subject[$/]
        subject = subject.split($/, 2)[0] + "..."
      end

      mailer.subject = "[ERROR] [#{request.host}] [#{config.environment}] #{subject}"
      mailer.text = trace
      mailer.set_header("X-Priority", 1)
      mailer.set_header("X-MSMail-Priority", "High")
      mailer.send!
    end

  end
end

Harbor::Dispatcher.register_event_handler(:exception) { |event| Harbor::ExceptionNotifier.notify(event.exception, event.request, event.response, event.trace) }
