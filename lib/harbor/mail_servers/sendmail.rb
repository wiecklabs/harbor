module Harbor
  module MailServers
    class Sendmail < Abstract

      attr_accessor :filter

      def initialize(config = {})
        @sendmail = config[:sendmail] || `which sendmail`.chomp
        @filter = config[:delivery_address_filter]
        @sender = config[:sender] || "bounce"
      end

      def deliver(message_or_messages)
        messages = Array === message_or_messages ? message_or_messages : [message_or_messages]

        messages.each do |message|
          filter.apply(message) if filter
          sendmail = ::IO.popen("#{@sendmail} -i -t -f#{@sender}", "w+")
          sendmail.write(message.to_s)
          sendmail.close_write
          sendmail.close_read
        end
      end
    end
  end
end