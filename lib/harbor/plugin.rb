require "harbor/accessor_injector"

module Harbor
  class Plugin

    class VariableMissingError < StandardError
      def initialize(klass, variable)
        super("#{klass} expected #{variable.inspect} to be present, but it wasn't.")
      end
    end

    include Harbor::AccessorInjector
    include Harbor::Hooks

    attr_accessor :context

    def initialize(context)
      @context = context
    end

    def self.requires(key)
      before(:to_s) do |instance|
        raise VariableMissingError.new(self, key) unless instance.instance_variable_defined?("@#{key}")
      end
    end

    def to_s
      raise NotImplementedError.new("You must define your own #to_s method.")
    end
    
  end
end