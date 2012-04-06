require_relative 'boot'
require 'fileutils'

public_path = config.root + "public"
Dir.mkdir public_path unless Dir.exists?(public_path)

config.assets.paths.each do |path|
  FileUtils.cp_r Dir["#{path}/**"], public_path
end
