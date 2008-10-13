module Wheels
  class AbstractMailServer
    def initialize(config = {})
    end

    def deliver(mail)
      raise NotImplementedError.new("Classes extending #{self.class.name} must implement #deliver(mail).")
    end
  end
end