module Harbor
  
  module IO
    
    class Bucket
      
      def initialize
        raise 'Abstract method called'
      end
      
      def directory?(relative_path)
        raise 'Abstract method called'
      end
      
      def exists?(relative_path)
        raise 'Abstract method called'
      end
      
      def files(relative_path)
        raise 'Abstract method called'
      end
      
      def mkdir_p(relative_path)
        raise 'Abstract method called'
      end
      
      def open(relative_path, mode = 'r', &block)
        raise 'Abstract method called'
      end
      
      def save(relative_path, file)
        raise 'Abstract method called'
      end
      
    end
    
  end
  
end