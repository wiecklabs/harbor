require "net/smtp"

class Harbor
  module Mail
    module Servers
      class SmtpServer < Abstract
        def initialize(config = {})
          @config = {}
          raise ArgumentError("You must provide the :address to your SMTP server in the SmtpServer config.") unless config.has_key?(:address)

          @config[:address] = config[:address]
          @config[:port] = config.fetch(:port, 25)
        end

        def deliver(message_or_messages)        
          messages = Array === message_or_messages ? message_or_messages : [message_or_messages]

          Net::SMTP.start(@config[:address], @config[:port]) do |smtp|
            messages.each do |message|
              smtp.send_message(message.to_s, message.from, message.to)
            end
          end
        end
      end
    end
  end
end