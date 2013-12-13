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

  class BadRequestError < StandardError
    attr_reader :request, :inner_exception
    def initialize(reason, request, exception = nil)
      @request = request
      @inner_exception = exception
      super(reason)
    end
  end

  class BadRequestParametersError < BadRequestError
    def initialize(request, error)
      super("Couldn't parse request parameters.", request, error)
    end
  end
end

require "harbor/configuration"