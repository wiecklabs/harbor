require "rubygems"
require "pathname"
require "test/unit"
require Pathname(__FILE__).dirname.parent + "lib/harbor"
require "harbor/xml_view"
require "harbor/mailer"
require "harbor/logging"
require "lib/harbor/logging/appenders/email"

require "harbor/cache/memory"
require "harbor/cache/disk"
require "harbor/test/test"
require "harbor/locale"

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

Harbor::Locale.default_culture_code = 'en-US'