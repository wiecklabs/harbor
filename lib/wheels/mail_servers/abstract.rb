module Wheels
  class AbstractMailServer
    def initialize(config = {})
    end

    def send(mail)
      raise NotImplementedError.new("Classes extending #{self.class.name} must implement #send(mail).")
    end
  end
end