require "zlib"

module Harbor

  # An IO class for zipping files suitable for sending via rack.
  class ZippedIO

    CENTRAL_DIRECTORY_ENTRY_SIGNATURE = 0x02014b50
    END_OF_CENTRAL_DIRECTORY_SIGNATURE = 0x06054b50

    def initialize(files)
      @files = files
    end

    def each
      zip_entries.each do |entry|
        yield entry.read_local_entry

        deflater = Deflater.new(entry.file)
        deflater.read do |data|
          yield data
        end
      end

      zip_central_directory.read do |data|
        yield data
      end
    end

    def size
      return @size if @size
      @size = 0
      zip_entries.each do |entry|
        @size += entry.size 
      end
      @files.each do |file|
        @size += ZippedIO::Deflater.new(file).size
      end
      @size += zip_central_directory.size
      @size
    end

    def zip_central_directory
      @zip_central_directory ||= ZipCentralDirectory.new(zip_entries)
    end

    def zip_entries
      @zip_entries ||= @files.map { |file| ZipEntry.new(file) }
    end

    @@block_size = 4096

    def self.block_size
      @@block_size
    end

    def self.block_size=(value)
      @@block_size = value
    end

    class Deflater

      attr_accessor :size

      def initialize(file, level = 0)
        @file = file
        @zlibDeflater = Zlib::Deflate.new(level, -Zlib::MAX_WBITS)
      end

      def read
        @file.rewind
        while data = @file.read(Harbor::ZippedIO::block_size)
          yield @zlibDeflater.deflate(data)
        end
        until @zlibDeflater.finished?
          yield @zlibDeflater.finish
        end
        nil
      end

      def size
        return @size if @size
        @size = 0
        @file.rewind
        while data = @file.read(Harbor::ZippedIO::block_size)
          @size += @zlibDeflater.deflate(data).size
        end
        
        until @zlibDeflater.finished?
          @size += @zlibDeflater.finish.size
        end
        @size
      end

    end

    class ZipCentralDirectory

      def initialize(entries)
        @entries = entries
      end

      def read
        generate unless @io

        @io.pos = 0
        while data = @io.read(Harbor::ZippedIO::block_size)
          yield data
        end
      end

      def size
        generate unless @io
        @io.size
      end

      private

      def generate
        @io = StringIO.new
        @io << [
          END_OF_CENTRAL_DIRECTORY_SIGNATURE,
          0, # number of this disk
          0, # numer of disk with start of central directory
          @entries.size,
          @entries.size,
          @entries.inject(0) { |value, entry| entry.central_directory_header_size + value },
          0, # offset
          0 # comment length
        ].pack('VvvvvVVv')
        @io << "" #comment
      end

    end

    class ZipEntry

      DEFLATED = 8

      FSTYPE_UNIX = 3

      LOCAL_ENTRY_SIGNATURE = 0x04034b50
      CENTRAL_DIRECTORY_STATIC_HEADER_LENGTH = 46

      attr_accessor :comment, :crc, :name, :size, :file

      def initialize(file)
        @file = file

        @crc = 0
        @compressed_size = file.size
        @size = file.size
      end

      def binary_dos_date
        (time.day) + (time.month << 5) + ((time.year - 1980) << 9)
      end

      def binary_dos_time
        (time.sec / 2) + (time.min << 5) + (time.hour << 11)
      end

      def central_directory_header_size
        CENTRAL_DIRECTORY_STATIC_HEADER_LENGTH + @file.name.size
      end

      def time
        Time.now
      end

      def read_local_entry
        generate unless @data
        @data
      end

      def size
        generate unless @data
        @data.size
      end

      private

      def generate
        @data ||= [
          ZipEntry::LOCAL_ENTRY_SIGNATURE,
          0,
          0,
          ZipEntry::DEFLATED,
          binary_dos_time,
          binary_dos_date,
          @crc, #crc
          @compressed_size,
          @size,
          @file.name.length,
          0 # extra length
        ].pack('VvvvvvVVVvv') << @file.name << ""
      end

    end

  end

end
