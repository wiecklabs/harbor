class Harbor
  class Messages < Hash
    def initialize(messages = {})
      super()
      merge!(messages) if messages
    end

    def [](key)
      @expired = true
      super
    end

    def expired?
      !!@expired
    end
  end
end