module Harbor
  module MailServers
    class Test < Abstract
      attr_accessor :messages
      
      def initialize(config = {})
        self.messages = []
      end

      def deliver(message_or_messages)
        messages.push(*message_or_messages)
      end
    end
  end
end