module Harbor
  module Hooks

    def self.included(target)
      target.extend(ClassMethods)

      target.class_eval do
        @__harbor_hooked_method_added = method(:method_added) if respond_to?(:method_added)
        def self.method_added(method)
          if !@__harbor_binding_method && hooks.has_key?(method)
            chain = hooks[method]
            chain.bind!
          end

          @__harbor_hooked_method_added.call(method) if @__harbor_hooked_method_added
        end
      end

    end

    class Map
      def initialize(target)
        @map = {}
        @target = target
      end

      def has_key?(method_name)
        @map.has_key?(method_name)
      end

      def [](method_name)
        @map[method_name] ||= Chain.new(@target, method_name)
      end
    end

    class Chain
      def initialize(target, method_name)
        @target = target
        @method_name = method_name
        @before = []
        @after = []

        bind! if target.instance_methods.include?(method_name.to_s)
      end

      def before(block)
        @before << block
      end

      def after(block)
        @after << block
      end

      def call(instance, args, blk = nil)
        result = nil

        catch(:halt) do
          @before.each do |block|
            block.call instance
          end

          result = instance.send("__hooked_#{@method_name}", *args, &blk)

          @after.each do |block|
            block.call instance
          end

          result
        end
      end

      def self.bind!(target, method_name)
        target.send(:alias_method, "__hooked_#{method_name}", method_name)

        target.send(:class_eval, <<-EOS)
          instance_variable_set(:@__harbor_binding_method, true)
          def #{method_name}(*args, &block)
            self.class.hooks[#{method_name.inspect}].call(self, args, block)
          end
          remove_instance_variable(:@__harbor_binding_method)
        EOS
      end

      def bind!
        self.class.bind!(@target, @method_name)
      end
    end

    module ClassMethods

      def hooks
        @hooks ||= Map.new(self)
      end

      def before(method_name, &block)
        hooks[method_name].before(block)
      end

      def after(method_name, &block)
        hooks[method_name].after(block)
      end

    end
  end
end