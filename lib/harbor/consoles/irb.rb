require "singleton"

class Harbor
  module Consoles
    module IRB
      
      def self.start

        if ::File.exists? ".irbrc"
          ENV['IRBRC'] = ".irbrc"
        end
        
        ARGV.clear
        
        require "irb"
        
        begin
          require "irb/completion"
        rescue Exception
          # No readline available, proceed anyway.
        end
        
        ::IRB.start
      end
      
    end
  end
end