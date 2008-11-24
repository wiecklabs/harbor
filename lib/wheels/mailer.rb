require "mailfactory"

require Pathname(__FILE__).dirname + "mail_servers/abstract"
require Pathname(__FILE__).dirname + "mail_servers/sendmail"

module Wheels
  class Mailer < MailFactory

    attr_accessor :mail_server

    def send!
      mail_server.deliver(self)
    end

  end
end