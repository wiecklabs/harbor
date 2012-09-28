require 'sprockets'

class Harbor
  class Assets
    extend Forwardable

    def_delegators :@sprockets_env, :prepend_path, :append_path, :cache=, :cache

    attr_reader :compile, :sprockets_env
    attr_accessor :mount_path, :precompiled_assets, :compress

    def initialize(sprockets_env = Sprockets::Environment.new)
      @paths = []
      @mount_path = 'assets'
      @sprockets_env = sprockets_env
      @sprockets_env.cache = Sprockets::Cache::FileStore.new("./tmp")
      @precompiled_assets = []
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

    def manifest
      @manifest ||= Sprockets::Manifest.new(@sprockets_env.index, "./public/#{@mount_path}/manifest.json")
    end

    def find_asset(path, type = nil)
      return nil if path =~ %r{^[-a-z]+://|^cid:|^//}

      if compile
        @sprockets_env.find_asset(path, type: type)
      else
        # TODO: Check if asset has been precompiled and raise an exception if
        #       it is not
        manifest.assets["#{path}.#{type}"]
      end
    end

    def asset_path(asset)
      asset = asset.logical_path unless asset.is_a? String
      "/#{@mount_path}/#{asset}"
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
