module Harbor

  module Events

    def self.included(target)
      target.extend(ClassMethods)
    end

    def raise_event(name, *args)
      if args.size == 1 && args.first.is_a?(Hash)
        args = EventContext.new(args.first)
      else
        warn "Using ordinal arguments when calling Harbor::Events#raise_event is deprecated. Harbor::Events#raise_event expects the name of the event, and a hash representing the context. (event name: #{name.inspect})\n\t#{caller.join("\n\t")}"
      end

      if self.class.events[name.to_s].nil?
        return false
      else
        self.class.events[name.to_s].each do |event|
          case event
          when Proc
            event.call(*args)
          when Class
            event.new(*args).call
          else
            raise "Unsupported handler class (#{event.class}) for event (#{name})"
          end
        end
        return true
      end
    end
    
    def raise_event2(name, event)
      registered_handlers = self.class.events[name.to_s]
      if registered_handlers.nil?
        false
      else
        registered_handlers.each do |handler|
          case handler
          when Proc
            handler.call(event)
          when Class
            handler.new(event).call
          else
            raise "Unsupported handler class (#{handler.class}) for event (#{name})"
          end
        end
        return true
      end
    end

    module ClassMethods

      def clear_events!(name = nil)
        warn "Harbor::Events::clear_events! has been deprecated. Use Harbor::Events::clear_event_handlers! instead."
        clear_event_handlers!(name)
      end

      def clear_event_handlers!(name = nil)
        if name
          events[name.to_s] = nil
        else
          class_variable_set(:@@events, {})
        end
      end

      def events
        class_variable_defined?(:@@events) ? class_variable_get(:@@events) : class_variable_set(:@@events, {})
      end

      def register_event(name, &block)
        warn  "Harbor::Events::register_event has been deprecated. Use Harbor::Events::register_event_handler instead."
        register_event_handler(name, nil, &block)
      end

      def register_event_handler(name, klass = nil, &block)
        if klass && block_given?
          raise "#{self.class}.register_event_handler expects a class OR a block, not both"
        elsif klass.nil? && !block_given?
          raise "#{self.class}.register_event_handler expects a class or a block"
        end

        if klass
          unless klass.is_a? Class
            raise "#{klass} is not a supported event handler; expected a class or block"
          end
          events[name.to_s] ||= []
          events[name.to_s] << klass
        elsif block_given?
          events[name.to_s] ||= []
          events[name.to_s] << block
        end
      end

    end

  end

end
