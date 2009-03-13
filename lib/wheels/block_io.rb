module Wheels
  class BlockIO
    def initialize(path_or_io)
      if path_or_io.is_a?(IO) || path_or_io.is_a?(StringIO)
        @io = path_or_io
        @size = @io.size
      else
        @io = File::open(path_or_io.to_s, 'r')
        @size = File.size(path_or_io.to_s)
      end
    end
    
    def to_s
      @io.read
    end
    
    def size
      @size
    end
    
    def close
      @io.close
    end
    
    BLOCK_SIZE = 500_000 # 500kb
    
    def each

      while data = @io.read(Wheels::BlockIO::BLOCK_SIZE) do
        yield data
      end

    end
  end
end