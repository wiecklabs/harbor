module Wheels
  class SendmailServer < AbstractMailServer
    def initialize(config = {})
      @sendmail = config[:sendmail] || `which sendmail`.chomp
    end

    def deliver(mail)
      sendmail = IO.popen("#{@sendmail} #{mail.to}", "w+")
      sendmail.puts mail.to_s
      sendmail.close
    end
  end
end