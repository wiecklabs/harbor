require "net/smtp"

module Wheels
  class SmtpServer < AbstractMailServer
    def initialize(config = {})
      @config = {}
      raise ArgumentError("You must provide the :address to your SMTP server in the SmtpServer config.") unless config.has_key?(:address)

      @config[:address] = config[:address]
      @config[:port] = config.fetch(:port, 25)
    end

    def deliver(mail)
      Net::SMTP.start(@config[:address], @config[:port]) do |smtp|
        smtp.send(mail.to_s, mail.from, mail.to)
      end
    end
  end
end