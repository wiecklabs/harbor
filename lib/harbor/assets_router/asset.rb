class Harbor
  class AssetsRouter
    class Asset
      def initialize(path)
        @path = path
      end

      def serve(response)
        response.cache(nil, ::File.mtime(@path), 86400) do
          response.stream_file(@path)
        end
      end
    end
  end
end
