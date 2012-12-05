ENV["RACK_ENV"] = "test"

require "doubleshot/setup"

require "minitest/autorun"
require "minitest/pride"
require "minitest/wscolor"

require Pathname(__FILE__).dirname.parent + "lib/harbor"
require "rack/test"
require "harbor/logging"
require "harbor/mailer"
require "harbor/test/test"
require "harbor/xml_view"

module MiniTest
  module Assertions

    def assert_nothing_raised *args
      yield
      assert true, "Nothing raised"
    rescue Exception => e
      fail "Expected nothing raised, but got #{e.class}: #{e.message}"
    end

    def assert_predicate o1, op, msg = nil
      msg = message(msg) { "Expected #{mu_pp(o1)} to be #{op}" }
      if !o1.respond_to?(op) && o1.respond_to?("#{op}?")
        assert o1.__send__("#{op}?"), msg
      else
        assert o1.__send__(op), msg
      end
    end

    def refute_predicate o1, op, msg = nil
      msg = message(msg) { "Expected #{mu_pp(o1)} to not be #{op}" }
      if !o1.respond_to?(op) && o1.respond_to?("#{op}?")
        refute o1.__send__("#{op}?"), msg
      else
        refute o1.__send__(op), msg
      end
    end
  end

  module Expectations
    # This is for aesthetics, so instead of:
    #   something.must_be :validate
    # Or:
    #   something.validate.must_equal true
    # Which are both terribly ugly, we can:
    #   something.must :validate
    infect_an_assertion :assert_operator, :must, :reverse
    infect_an_assertion :refute_operator, :wont, :reverse

    infect_an_assertion :assert_nothing_raised, :wont_raise
  end
end

module Helper
  def self.tmp(path = "tmp")
    dir = Pathname(path.to_s)
    dir.rmtree if dir.exist?
    dir.mkpath

    yield dir

  ensure
    dir.rmtree if dir.exist?
  end

  def self.upload(filename)
    input = <<EOF
--AaB03x\r
Content-Disposition: form-data; name="file"; filename="#{filename}"\r
Content-Type: image/jpeg\r
\r
#{File.read(Pathname(__FILE__).dirname + "samples" + filename)}\r
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
                      "CONTENT_LENGTH" => input.size,
                      :input => input)
  end

  class MyApplication < Harbor::Application
    def self.public_path
      Pathname(__FILE__).dirname + "public"
    end
  end

  include Rack::Test::Methods

  class Browser
    def initialize
      @request_log = StringIO.new
      @error_log = StringIO.new

      logger = Logging::Logger['request']
      logger.clear_appenders
      logger.add_appenders Logging::Appenders::IO.new('request', @request_log)

      logger = Logging::Logger['error']
      logger.clear_appenders
      logger.add_appenders Logging::Appenders::IO.new('error', @error_log)

      @router = Harbor::Router.new
      @container = Harbor::Container.new
      @application = MyApplication.new(@container, @router)

      @session = Rack::Test::Session.new(Rack::MockSession.new(@application))
    end

    def session
      @session
    end

    def capture_stderr(&block)
      $stderr = StringIO.new

      yield

      result = $stderr.string
      $stderr = STDERR

      result
    end
  end
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