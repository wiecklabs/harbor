require_relative 'boot'
require 'fileutils'

public_path = config.root + "public/#{config.assets.mount_path}"
FileUtils.mkdir_p public_path unless Dir.exists?(public_path)

Bundler.require(:assets)

if config.assets.compress
  if Object.const_defined? :Uglifier
    config.assets.sprockets_env.js_compressor = Uglifier.new(mangle: true)
  end

  if Object.const_defined? :YUI
    config.assets.sprockets_env.css_compressor = YUI::CssCompressor.new
  end
end

config.assets.manifest.clean
unless config.assets.precompiled_assets.empty?
  config.assets.manifest.compile(config.assets.precompiled_assets)
end
