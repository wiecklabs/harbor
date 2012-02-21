module Harbor
  module Mail
    module Servers
      class Test < Abstract
        attr_accessor :messages
      
        def initialize(config = {})
          self.messages = []
        end

        def deliver(message_or_messages)
          messages = Array === message_or_messages ? message_or_messages : [message_or_messages]

          messages.push(*messages)
        end
      end
    end
  end
end