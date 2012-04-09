require_relative 'boot'
require 'fileutils'

public_path = config.root + "public/#{config.assets.mount_path}"
FileUtils.mkdir_p public_path unless Dir.exists?(public_path)

config.assets.paths.each do |path|
  FileUtils.cp_r Dir["#{path}/**"], public_path
end
