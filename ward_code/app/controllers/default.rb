class Wieck
  class Controllers
    class Default < Wieck::Controllers::Base
      
      # Default method
      def index
        puts "How now brown cow!"
        render
      end
      
    end
  end
end