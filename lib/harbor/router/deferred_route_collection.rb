require 'forwardable'

module Harbor
  class Router
    class DeferredRouteCollection
      extend ::Forwardable

      # TODO: Do we really need all of this or can we just provide a #to_a / #to_ary ?
      def_delegators :@array, :sort!, :empty?, :size, :delete_at, :slice!, :first

      def initialize
        @array = []
      end

      def <<(route)
        # TODO: Make sure this will scale
        index = @array.find_index { |r| r.normalized_tokens == route.normalized_tokens }
        @array.delete_at(index) if index
        @array << route
      end
    end
  end
end
