require "rubygems"
require "bundler/setup" unless Object::const_defined?("Bundler")

if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start do
    add_filter "/test/"
  end
end

require "pathname"
require "minitest/autorun"
require 'mocha'
require "uri"
require Pathname(__FILE__).dirname.parent + "lib/harbor"
require "harbor/mail/mailer"
require "harbor/logging"
require "harbor/logging/appenders/email"
require "harbor/test/test"
require "rack/test"
require "builder"

ENV['RACK_ENV'] = 'test'

(Harbor::Mail::Builder.private_instance_methods - Object.private_instance_methods).each do |method|
  Harbor::Mail::Builder.send(:public, method)
end

class Time

  class << self

    ##
    # Time.warp
    #   Allows you to stub-out Time.now to return a pre-determined time for calls to Time.now.
    #   Accepts a Fixnum to be added to the current Time.now, or an instance of Time
    #
    #   item.expires_at = Time.now + 10
    #   assert(false, item.expired?)
    #
    #   Time.warp(10) do
    #     assert(true, item.expired?)
    #   end
    ##
    def warp(time)
      @warp = time.is_a?(Fixnum) ? (Time.now + time) : time
      yield
      @warp = nil
    end

    # class load mojo to prevent multiple-aliasing of Time.now when helper.rb gets reloaded between tests
    unless @included
      alias original_now now
    end
    @included = true

    def now
      @warp || original_now
    end

  end

end

class String

  ##
  # Remove whitespace margin.
  #
  # @return [String] receiver with whitespace margin removed
  #
  # @api public
  def margin
    lines = self.dup.split($/)

    min_margin = 0
    lines.each do |line|
      if line =~ /^(\s+)/ && (min_margin == 0 || $1.size < min_margin)
        min_margin = $1.size
      end
    end
    lines.map { |line| line.sub(/^\s{#{min_margin}}/, '') }.join($/)
  end

end


class MiniTest::Unit::TestCase

  def capture_stderr(&block)
    $stderr = StringIO.new

    yield

    result = $stderr.string
    $stderr = STDERR

    result
  end

  def assert_route_matches(http_method, path)
    action = Harbor::Router::instance.match(http_method, path).action
    refute_nil(action, "Expected router match for #{http_method}:#{path}, got nil.")

    yield(action) if block_given?
  end

  def assert_controller_route_matches(http_method, path, controller, method_name)
    action = Harbor::Router::instance.match(http_method, path).action

    assert_kind_of(Harbor::Controller::Action, action)
    assert_equal(controller, action.controller)
    assert_equal(method_name, action.name)
  end

end

def upload(filename)
  input = <<-EOF
--AaB03x\r
Content-Disposition: form-data; name="file"; filename="#{filename}"\r
Content-Type: image/jpeg\r
\r
#{File.read(Pathname(__FILE__).dirname + "fixtures/samples" + filename)}\r
\r
--AaB03x\r
Content-Disposition: form-data; name="video[caption]"\r
\r
test\r
--AaB03x\r
Content-Disposition: form-data; name="video[transcoder][1]"\r
\r
on\r
--AaB03x\r
Content-Disposition: form-data; name="video[transcoder][4]"\r
\r
on\r
--AaB03x\r
Content-Disposition: form-data; name="video[transcoder][5]"\r
\r
on\r
--AaB03x--\r
\r
EOF
  Rack::Request.new Rack::MockRequest.env_for("/",
                    "CONTENT_TYPE" => "multipart/form-data, boundary=AaB03x",
                    "CONTENT_LENGTH" => input.bytesize,
                    :input => input)
end
