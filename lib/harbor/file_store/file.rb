module Harbor
  class FileStore
    class File

      attr_accessor :store, :path

      def initialize(store, path)
        @store = store
        @path = path
      end

      def read(bytes = nil)
        open
        @stream.read(bytes)
      end

      def size
        store.size(path)
      end

      def open
        @stream ||= store.open(path)
      end

    end
  end
end