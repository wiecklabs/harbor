require "mailfactory"

require Pathname(__FILE__).dirname + "mail_servers/abstract"
require Pathname(__FILE__).dirname + "mail_servers/sendmail"
require Pathname(__FILE__).dirname + "mail_servers/smtp"

module Wheels
  class Mailer < MailFactory

    attr_accessor :mail_server

    def send!
      mail_server.deliver(self)
    end

  end
end