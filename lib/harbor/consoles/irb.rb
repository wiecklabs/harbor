require "singleton"

module Harbor
  module Consoles
    module IRB
      
      def self.start
        require "irb"
        
        begin
          require "irb/completion"
        rescue Exception
          # No readline available, proceed anyway.
        end

        if ::File.exists? ".irbrc"
          ENV['IRBRC'] = ".irbrc"
        end
        
        ::IRB.start
      end
      
    end
  end
end