class Harbor
  module Mail
    module Servers
      class Abstract
        def initialize(config = {})
        end

        def deliver(message_or_messages)
          raise NotImplementedError.new("Classes extending #{self.class.name} must implement #deliver(message_or_messages).")
        end
      end
    end
  end
end