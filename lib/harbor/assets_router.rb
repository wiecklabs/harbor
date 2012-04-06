require_relative "assets_router/asset"

class Harbor
  class AssetsRouter
    def self.instance
      @instance ||= self.new
    end

    def match(request)
      return unless config.assets.serve_static

      pattern = "{#{config.assets.paths.join(',')}}/#{request.path_info}"
      return unless file = Dir[pattern].first

      Asset.new(file)
    end
  end
end
