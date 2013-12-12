require "rubygems"
require "pathname"

$:.unshift(Pathname(__FILE__).dirname.expand_path.to_s)

require "harbor/version"
require "harbor/support/array"
require "harbor/support/blank"
require "harbor/container"
require "harbor/locale"
require "harbor/hooks"
require "harbor/file_store"
require "harbor/shellwords"
require "harbor/file"
require "harbor/checksum"
require "harbor/router"
require "harbor/application"
require "harbor/cascade"
require "harbor/plugin"
require "harbor/mime"
require "harbor/errors"

require "harbor/cache"

module Harbor
  def self.env_path
    @env_path ||= Pathname(__FILE__).dirname.parent + "env"
  end

  class BadRequestParametersError < StandardError
    def initialize(error)
      super(<<-MSG.gsub(/^\s+/x, ''))
        Non-fatal exception #{error.class} occurred that prevented the request from being processed.

        Message:
        #{error.message}

        Backtrace:
        -------------------------------------------------
        #{error.backtrace.join("\n\t")}
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      MSG
    end
  end
end

require "harbor/configuration"