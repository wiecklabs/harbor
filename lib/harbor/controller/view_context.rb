module Harbor
  class Controller
    module ViewContext
      def render(view)
        response.render view, __extract_context_hash
      end

      private

      def __extract_context_hash
        instance_variables.each_with_object({}) do |var, hash|
          key = var.to_s[1..-1]
          hash[key] = instance_variable_get(var)
        end
      end
    end
  end
end
