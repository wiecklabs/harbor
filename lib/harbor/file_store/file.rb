class Harbor
  class FileStore
    class File

      attr_accessor :store, :path

      def initialize(store, path)
        @store = store
        @path = path
        
        @pending_writes = []
      end

      def copy_on_write
        return @copy_on_write if @copy_on_write

        @copy_on_write = []
        if store.options[:copy_on_write]
          store.options[:copy_on_write].each do |name|
            @copy_on_write << Harbor::FileStore[name].get(@path)
          end
        end

        @copy_on_write
      end

      def copy_on_read
        return @copy_on_read if @copy_on_read

        @copy_on_read = []
        if store.options[:copy_on_read]
          store.options[:copy_on_read].each do |name|
            @copy_on_read << Harbor::FileStore[name].get(@path)
          end
        end

        @copy_on_read
      end

      def write(data)
        open("wb")

        copy_on_write.each do |file|
          if store.options[:async_copy]
            @pending_writes << lambda { file.write(data) }
          else
            file.write(data)
          end
        end

        if data
          @stream.write(data)
        else
          @stream.close
          @stream = nil
          
          Thread.new {
            @pending_writes.each { |write| write.call }
            @pending_writes = []
          } if store.options[:async_copy]
        end
      end

      def read(bytes = nil)
        open("r")

        data = @stream.read(bytes)

        copy_on_read.each { |file| file.write(data) }

        unless bytes && data
          @stream.close
          @stream = nil
        end

        data
      end

      def size
        store.size(path)
      end

      def open(mode = "r")
        @stream ||= store.open(path, mode)
      end

      def close
        @stream.close if @stream
        @stream = nil
      end

      ##
      # Returns the full path to this file
      ##
      def absolute_path
        (@store.root + @path).to_s
      end
      
      def exists?
        store.exists?(path)
      end

    end
  end
end
