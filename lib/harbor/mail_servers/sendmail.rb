module Harbor
  module MailServers
    class Sendmail < Abstract
      def initialize(config = {})
        @sendmail = config[:sendmail] || `which sendmail`.chomp
        @filter = config[:delivery_address_filter]
      end

      def deliver(message_or_messages)
        messages = Array === message_or_messages ? message_or_messages : [message_or_messages]

        messages.each do |message|
          @filter.apply(message) if @filter

          sendmail = ::IO.popen("#{@sendmail} -i -t", "w+")
          sendmail.puts message.to_s
          sendmail.close
        end
      end
    end
  end
end