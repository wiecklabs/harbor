require "singleton"

module Harbor
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
        
        catch(:IRB_EXIT) do
          ::IRB.start
        end
        exit
      end
      
    end
  end
end