module Harbor
  module Test
    class Session < Harbor::Session

      attr_accessor :request

      def initialize(session_data = {})
        @data = session_data
      end

      def save
      end

    end
  end
end