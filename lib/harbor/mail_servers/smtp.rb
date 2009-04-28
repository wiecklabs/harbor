require "net/smtp"

module Harbor
  module MailServers
    class SmtpServer < Abstract
      def initialize(config = {})
        @config = {}
        raise ArgumentError("You must provide the :address to your SMTP server in the SmtpServer config.") unless config.has_key?(:address)

        @config[:address] = config[:address]
        @config[:port] = config.fetch(:port, 25)
      end

      def deliver(mail)
        Net::SMTP.start(@config[:address], @config[:port]) do |smtp|
          smtp.send_message(mail.to_s, mail.from, mail.to)
        end
      end
    end
  end
end