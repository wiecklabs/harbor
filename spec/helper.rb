require "rubygems"
require "spec"
require Pathname(__FILE__).dirname.parent + "lib/framework"

module Rack
  class Request
    def params
      @params ||= {}
    end
  end
end