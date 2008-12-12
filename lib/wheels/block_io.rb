module Wheels
  class BlockIO
    def initialize(path)
      @path = path
    end
    
    def to_s
      File.read(@path)
    end
    
    def size
      File.size(@path)
    end
    
    BLOCK_SIZE = 500_000 # 500kb
    
    def each
      File::open(@path, "r") do |file|
        while data = file.read(Wheels::BlockIO::BLOCK_SIZE) do
          yield data
        end
      end
    end
  end  
end