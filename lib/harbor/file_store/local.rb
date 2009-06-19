module Harbor
  class FileStore
    class Local < Harbor::FileStore

      attr_accessor :path, :options

      def initialize(path, options = {})
        @path = Pathname(path)

        @options = options
      end

      def get(path)
        Harbor::FileStore::File.new(self, path)
      end

      def put(path, file)
        f = Harbor::FileStore::File.new(self, path)

        ::FileUtils.mkdir_p((@path + path).parent.to_s) unless (@path + path).parent.exist?

        while data = file.read(500_000)
          f.write data
        end

        f.write nil
      end

      def delete(path)
        ::FileUtils.rm(@path + path)
        Harbor::File.rmdir_p((@path + path).parent.to_s)
      end

      def exists?(path)
        (@path + path).exist?
      end

      def open(path, mode = "r", &block)
        ::File.open(@path + path, mode, &block)
      end

      def size(path)
        ::File.size(@path + path)
      end

      def local?
        true
      end

    end
  end
end