module Harbor
  class FileStore
    class Local < Harbor::FileStore

      attr_accessor :path, :options

      def initialize(path, options = {})
        @path = Pathname(path)

        @options = options

        ::FileUtils.mkdir_p(path.to_s)
      end

      def get(path)
        Harbor::FileStore::File.new(self, path)
      end

      def put(path, file)
        f = Harbor::FileStore::File.new(self, path)

        size = file.is_a?(::File) ? ::File.size(file) : file.size
        cleanup(size)

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

      private

      def __size__
        `du -sk #{Shellwords.escape(@path.to_s)} | awk '{ print $1; }'`.chomp.to_i * 1024
      end

      def cleanup(space = nil)
        size = __size__
        size -= space if space # make room for a specified file size if specified

        return false unless @options[:cache_size] && size > @options[:cache_size]

        Dir[@path + "**/*"].each do |file|
          next unless ::File.ctime(file) < Time.now - (@options[:cache_time] || 60)

          file = Pathname(file).relative_path_from(@path)

          size -= size(file)
          delete(file)

          break if size < @options[:cache_size]
        end

        true
      end

    end
  end
end