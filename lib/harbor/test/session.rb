module Harbor
  module Test
    class Session < Harbor::Session

      def initialize(session_data = {})
        @data = session_data
      end

    end
  end
end