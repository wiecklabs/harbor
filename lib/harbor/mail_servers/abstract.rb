module Harbor
  module MailServers
    class Abstract
      def initialize(config = {})
      end

      def deliver(mail)
        raise NotImplementedError.new("Classes extending #{self.class.name} must implement #deliver(mail).")
      end
    end
  end
end