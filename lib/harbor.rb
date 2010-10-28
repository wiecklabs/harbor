require "rubygems"
require "pathname"

$:.unshift(Pathname(__FILE__).dirname.expand_path.to_s)

require "harbor/version"
require "harbor/support/array"
require "harbor/container"
require "harbor/configuration"
require "harbor/locale"
require "harbor/cache"
require "harbor/hooks"
require "harbor/file_store"
require "harbor/shellwords"
require "harbor/file"
require "harbor/router"
require "harbor/application"
require "harbor/cascade"
require "harbor/plugin"
require "harbor/mime"
require "harbor/errors"

module Harbor
  def self.env_path
    @env_path ||= Pathname(__FILE__).dirname.parent + "env"
  end
end