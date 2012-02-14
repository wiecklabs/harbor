require "rubygems"
require "bundler/setup"

require "pathname"
require "test/unit"
require "uri"
require Pathname(__FILE__).dirname.parent + "lib/harbor"
require "harbor/xml_view"
require "harbor/mailer"
require "harbor/logging"
require "lib/harbor/logging/appenders/email"
require "harbor/test/test"
require "rack/test"

ENV['RACK_ENV'] = 'test'

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

class Test::Unit::TestCase
  
  class MyApplication < Harbor::Application
    def self.public_path
      Pathname(__FILE__).dirname + "public"
    end
  end
  
  include Rack::Test::Methods

  def setup_browser!
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
    
    @browser = Rack::Test::Session.new(Rack::MockSession.new(@application))
  end
  
  def browser
    @browser
  end
    
  def capture_stderr(&block)
    $stderr = StringIO.new

    yield

    result = $stderr.string
    $stderr = STDERR

    result
  end
end

def upload(filename)
  input = <<-EOF
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