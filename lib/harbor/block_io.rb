class Harbor
  ##
  # Used by Harbor::Response#send_file and Harbor::Response#stream_file to send
  # large files or streams in chunks. This is a fallback measure for the cases
  # where X-Sendfile cannot be used.
  ##
  class BlockIO

    def self.block_size
      @@block_size ||= 500_000 # 500kb
    end
    
    def self.block_size=(value)
      raise ArgumentError.new("Harbor::BlockIO::block_size value must be a Fixnum") unless value.is_a?(Fixnum)
      @@block_size = value
    end
    
    def initialize(path_or_io)
      case path_or_io
      when ::IO
        @io = path_or_io
        @size = @io.stat.size
      when StringIO
        @io = path_or_io
        @size = @io.size
      when Harbor::FileStore::File
        @io = path_or_io
        @size = @io.size
        @path = path_or_io.absolute_path
      when Pathname
        @path = path_or_io.expand_path.to_s
        @io = path_or_io.open('r')
        @size = path_or_io.size
      else
        @path = path_or_io.to_s
        @io = ::File::open(@path, 'r')
        @size = ::File.size(@path)
      end
    end

    def path
      @path
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

    def each
      while data = @io.read(Harbor::BlockIO::block_size) do
        yield data
      end
    end
  end
end