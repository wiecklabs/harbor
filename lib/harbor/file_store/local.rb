module Harbor
  class FileStore
    class Local < Harbor::FileStore

      def initialize(path)
        @path = Pathname(path)
      end

      def put(path, file)
        open(path, "wb") do |f|
          while data = file.read(500_000)
            f.write data
          end
        end
      end

      def delete(path)
        ::FileUtils.rm(@path + path)
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