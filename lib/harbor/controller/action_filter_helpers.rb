class Harbor
  class Controller
    # TODO: Documentation
    # TODO: Make it work with inheritance
    module ActionFilterHelpers
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def before(*args, &block)
          filters[:before] << ActionFilter.new(self, *args, block)
        end

        def after(*args, &block)
          filters[:after] << ActionFilter.new(self, *args, block)
        end

        def filters
          @filters ||= {:before => [], :after => []}
        end
      end

      def filter!(type)
        self.class::filters[type].each do |action_filter|
          action_filter.filter! self
        end
      end
    end
  end
end
