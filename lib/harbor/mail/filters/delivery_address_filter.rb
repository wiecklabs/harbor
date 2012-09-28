class Harbor
  module Mail
    module Filters
      class DeliveryAddressFilter

        def initialize(overridden_delivery_address, whitelist_expression)
          @overridden_delivery_address = overridden_delivery_address
          @whitelist_expression = whitelist_expression
        end

        def apply(message)
          unless @whitelist_expression && (message.to =~ @whitelist_expression)
            message.add_header('X-Overridden-To', message.to) if message.respond_to?(:add_header)
            message.to = @overridden_delivery_address
          end
          message
        end

      end
    end
  end
end