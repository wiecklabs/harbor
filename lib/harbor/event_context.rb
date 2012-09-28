module Harbor

  class EventContext

    def initialize(context = nil)
      context ||= {}
      raise ArgumentError, "EventContent#new expects a Hash for the first parameter" unless context.is_a? Hash

      @context = {}
      context.each_pair do |key, value|
        @context[key.to_sym] = value
      end
    end

    def method_missing(method)
      if @context.has_key?(method)
        @context[method]
      else
        raise NoMethodError, "method #{method.to_s} not defined for EventContext"
      end
    end

  end

end
