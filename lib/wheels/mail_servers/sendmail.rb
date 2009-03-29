module Wheels
  module MailServers
    class Sendmail < Abstract
      def initialize(config = {})
        @sendmail = config[:sendmail] || `which sendmail`.chomp
      end

      def deliver(mail)
        sendmail = IO.popen("#{@sendmail} -i -t", "w+")
        sendmail.puts mail.to_s
        sendmail.close
      end
    end
  end
end