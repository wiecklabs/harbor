require "mailfactory"

require Pathname(__FILE__).dirname + "mail_servers/abstract"
require Pathname(__FILE__).dirname + "mail_servers/sendmail"

module Wheels
  class Mailer < MailFactory

    attr_accessor :server

    def initialize(server)
      super()
      @server = server
    end

    def send!
      self.server.deliver(self)
    end

  end
end