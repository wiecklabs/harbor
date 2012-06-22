require "singleton"

class Harbor
  module Consoles
    module Pry

      def self.start
        require "pry"
        ::Pry.start
      end

    end
  end
end
