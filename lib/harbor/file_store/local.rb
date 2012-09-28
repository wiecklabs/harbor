module Harbor
  class FileStore
    class Local < Harbor::FileStore

      attr_accessor :root, :options

      @@file_mask = 0640
      def self.file_mask
        @@file_mask
      end

      def self.file_mask=(value)
        @@file_mask = value
      end

      def initialize(path, options = {})
        path = "#{path}/" unless path =~ /.*\/$/
        @root = Pathname(path)

        @options = options

        ::FileUtils.mkdir_p(path.to_s)
      end

      def get(path)
        path = strip_leading_slash(path)
        Harbor::FileStore::File.new(self, path)
      end

      def put(path, absolute_path)
        raise ArgumentError.new("Harbor::FileStore::Local#put[absolute_path] should be a path but was an IO") if absolute_path.is_a?(IO)
        path = strip_leading_slash(path)
        file = Harbor::FileStore::File.new(self, path)

        unless (@root + path).parent.exist?
          ::FileUtils.mkdir_p((@root + path).parent.to_s) 
        end

        ::FileUtils::cp(absolute_path, file.absolute_path)
        ::FileUtils::chmod(Harbor::FileStore::Local.file_mask, file.absolute_path)
        file
      end

      def delete(path)
        path = strip_leading_slash(path)
        ::FileUtils.rm(@root + path)
        Harbor::File.rmdir_p((@root + path).parent.to_s)
      end

      def exists?(path)
        path = strip_leading_slash(path)
        (@root + path).exist?
      end

      def open(path, mode = "r", &block)
        path = strip_leading_slash(path)
        ::FileUtils.mkdir_p((@root + path).parent.to_s) unless (@root + path).parent.exist?
        ::File.open(@root + path, mode, &block)
      end

      def size(path)
        path = strip_leading_slash(path)
        ::File.size(@root + path)
      end

      def local?
        true
      end

      private

      def __size__
        `du -sk #{Shellwords.escape(@root.to_s)} | awk '{ print $1; }'`.chomp.to_i * 1024
      end
      
      def strip_leading_slash(path)
        path = path[1..path.size - 1] if path =~ /^\//
        path
      end

    end
  end
end
