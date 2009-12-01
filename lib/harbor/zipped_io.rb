require "zlib"

module Harbor

  # An IO class for zipping files suitable for sending via rack.
  class ZippedIO

    DEFAULT_BLOCK_SIZE = 4096

    CENTRAL_DIRECTORY_ENTRY_SIGNATURE = 0x02014b50
    END_OF_CENTRAL_DIRECTORY_SIGNATURE = 0x06054b50

    def initialize(files)
      @files = files
    end

    def compute_metadata
      return false if @metadata_computed

      @total_compressed_size = 0

      @offset = 0
      zip_entries.each do |entry|
        entry.local_header_offset = @offset

        crc = Zlib::crc32
        compressed_size = 0
        uncompressed_size = 0

        entry.file.rewind
        zlibDeflater = Zlib::Deflate.new(0, -Zlib::MAX_WBITS)
        while data = entry.file.read(Harbor::ZippedIO::block_size)
          crc = Zlib::crc32(data.to_s, crc)
          uncompressed_size += data.size
          compressed_size += zlibDeflater.deflate(data).size
        end
        until zlibDeflater.finished?
          compressed_size += zlibDeflater.finish.size
        end

        entry.crc = crc
        entry.compressed_size = compressed_size
        entry.uncompressed_size = uncompressed_size

        @offset += compressed_size + entry.read_local_entry.size

        @total_compressed_size += compressed_size
      end

      @total_compressed_size += zip_central_directory.size

      true
    end

    def each
      compute_metadata

      zip_entries.each do |entry|
        yield entry.read_local_entry

        entry.file.rewind
        zlibDeflater = Zlib::Deflate.new(0, -Zlib::MAX_WBITS)
        while data = entry.file.read(Harbor::ZippedIO::block_size)
          yield zlibDeflater.deflate(data)
        end
        until zlibDeflater.finished?
          yield zlibDeflater.finish
        end
      end

      zip_central_directory.read do |data|
        yield data
      end
    end

    def size
      compute_metadata
      @total_compressed_size
    end

    def zip_central_directory
      @zip_central_directory ||= ZipCentralDirectory.new(zip_entries, @offset)
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

    class ZipCentralDirectory

      DEFLATED = 8

      FSTYPE_UNIX = 3

      def initialize(entries, offset)
        @entries = entries
        @offset = offset
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

      def binary_dos_date
        (time.day) + (time.month << 5) + ((time.year - 1980) << 9)
      end

      def binary_dos_time
        (time.sec / 2) + (time.min << 5) + (time.hour << 11)
      end

      def generate
        @io = StringIO.new

        size = 0

        unix_permissions = 0644
        external_file_attributes = (FSTYPE_UNIX << 12 | (unix_permissions & 07777)) << 16

        @entries.each do |entry|
          data = [
            CENTRAL_DIRECTORY_ENTRY_SIGNATURE,
            0, # version
            FSTYPE_UNIX,
            0,
            0,
            DEFLATED,
            binary_dos_time,
            binary_dos_date,
            entry.crc,
            entry.compressed_size,
            entry.uncompressed_size,
            entry.name.length,
            0, # extra length
            0, # comment length
            0, # disk number start
            1, # internal file attributes
            external_file_attributes,
            entry.local_header_offset,
            entry.name,
            '', #extra
            '' #comment
          ].pack('VCCvvvvvVVVvvvvvVV') << entry.name << ""
          size += data.size
          @io << data
        end

        @io << [
          END_OF_CENTRAL_DIRECTORY_SIGNATURE,
          0, # number of this disk
          0, # numer of disk with start of central directory
          @entries.size,
          @entries.size,
          @entries.inject(0) { |value, entry| entry.central_directory_header_size + value },
          # size,
          @offset,
          0 # comment length
        ].pack('VvvvvVVv')
        @io << "" #comment
      end

      def time
        @time ||= Time.now
      end

    end

    class ZipEntry

      DEFLATED = 8

      FSTYPE_UNIX = 3

      LOCAL_ENTRY_SIGNATURE = 0x04034b50
      CENTRAL_DIRECTORY_STATIC_HEADER_LENGTH = 46

      attr_accessor :comment, :crc, :file
      attr_accessor :compressed_size, :uncompressed_size
      attr_accessor :local_header_offset

      def initialize(file)
        @file = file
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

      def name
        @file.name
      end

      def time
        @time ||= Time.now
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
        @data ||= ([
          ZipEntry::LOCAL_ENTRY_SIGNATURE,
          0,
          0,
          ZipEntry::DEFLATED,
          binary_dos_time,
          binary_dos_date,
          @crc, #crc
          @compressed_size,
          @uncompressed_size,
          @file.name.length,
          0 # extra length
        ].pack('VvvvvvVVVvv') << @file.name << "")
      end

    end

  end

end
