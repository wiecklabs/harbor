require "singleton"

class Harbor
  module Consoles
    module Pry

      def self.start
        require "pry"
        ::Object.new.pry
      end

    end
  end
end