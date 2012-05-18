require 'sprockets'

class Harbor
  class Assets
    extend Forwardable

    def_delegators :@sprockets_env, :prepend_path, :append_path, :cache=, :cache

    attr_reader :compile, :sprockets_env, :manifest
    attr_accessor :mount_path

    def initialize(sprockets_env = Sprockets::Environment.new)
      @paths = []
      @mount_path = 'assets'
      @sprockets_env = sprockets_env
      @sprockets_env.cache = Sprockets::Cache::FileStore.new("./tmp")
      @manifest = Sprockets::Manifest.new(@sprockets_env, "./public/#{@mount_path}/manifest.json")
    end

    def compile=(compile)
      @compile = compile

      if @compile
        cascade << self
        Bundler.require(:assets)
      else
        cascade.unregister(self)
      end
    end

    def match(request)
      return unless compile
      !!@sprockets_env[fix_path_info(request.env['PATH_INFO'])]
    end

    def call(request, response)
      env = fix_env_path_info(request.env.dup)
      Harbor::Dispatcher::RackWrapper.call(@sprockets_env, env, response)
    end

    private

    def cascade
      @cascade ||= Harbor::Dispatcher.instance.cascade
    end

    def fix_env_path_info(env)
      env['PATH_INFO'] = fix_path_info(env['PATH_INFO'])
      env
    end

    def fix_path_info(path_info)
      path_info.gsub(/(\/)?#{@mount_path}\//, '')
    end
  end
end
