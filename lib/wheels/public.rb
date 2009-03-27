module Wheels
  ##
  # Rack Middleware for serving up public files.
  # 
  #   use Wheels::Public, MyApp.public_path, OtherApp.public_path
  ##
  class Public

    FILE_METHODS = %w(GET HEAD).freeze

    def initialize(app, *public_folders)
      @app = app
      @public_folders = public_folders.map { |folder| Pathname(folder) }
    end

    def call(env)
      path = env['PATH_INFO'].chomp('/')
      method = env['REQUEST_METHOD']

      if path != "" && FILE_METHODS.include?(method) && public_folder = public_folder_for(path)
        Rack::File.new(public_folder).call(env)
      else
        @app.call(env)
      end
    end

    private

    def public_folder_for(path)
      @public_folders.detect { |folder| File.file?(folder + Rack::Utils.unescape(path)[1..-1]) }
    end

  end
end