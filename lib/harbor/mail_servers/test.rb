module Harbor
  module MailServers
    class Test < Abstract
      attr_accessor :messages
      
      def initialize(config = {})
        self.messages = []
      end

      def deliver(mail)
        messages.push(mail)
      end
    end
  end
end