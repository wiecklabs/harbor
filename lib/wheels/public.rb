module Wheels
  class Public

    FILE_METHODS = %w(GET HEAD).freeze

    def initialize(app, root)
      @app = app
      @root = Pathname(root)
    end

    def call(env)
      path = env['PATH_INFO'].chomp('/')
      method = env['REQUEST_METHOD']

      if path != "" && FILE_METHODS.include?(method) && file_exists?(path)
        Rack::File.new(@root + "public").call(env)
      else
        @app.call(env)
      end
    end

    private

    def file_exists?(path)
      full_path = @root + "public" + Rack::Utils.unescape(path)[1..-1]
      File.exists?(full_path) && !File.directory?(full_path)
    end

  end
end