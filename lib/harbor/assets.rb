class Harbor
  class Assets
    attr_reader :serve_static, :paths
    attr_accessor :mount_path

    def initialize(cascade = nil)
      @paths = []
      @mount_path = 'assets'
      @cascade = cascade
    end

    def serve_static=(serve_static)
      @serve_static = serve_static

      if @serve_static
        cascade << self
      else
        cascade.unregister(self)
      end
    end

    def match(request)
      return unless serve_static

      find_file(request.path_info)
    end

    def call(request, response)
      path = find_file(request.path_info)
      response.cache(nil, ::File.mtime(path), 86400) do
        response.stream_file(path)
      end
    end

    private

    def cascade
      @cascade ||= Harbor::Dispatcher.instance.cascade
    end

    def find_file(file)
      file = file.gsub("#{@mount_path}/", '')
      pattern = "{#{paths.join(',')}}/#{file}"
      Dir[pattern].first
    end
  end
end
