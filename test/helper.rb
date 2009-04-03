require "rubygems"
require "pathname"
require "test/unit"
require Pathname(__FILE__).dirname.parent + "lib/wheels"
require "wheels/xml_view"
require "wheels/mailer"

module Rack
  class Request
    def params
      @params ||= {}
    end
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