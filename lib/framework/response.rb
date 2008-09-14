require "stringio"
require "erubis"

class Response < StringIO

  attr_accessor :application, :status, :content_type, :headers

  def initialize(application)
    @application = application
    @headers = {}
    @content_type = "text/html"
    @status = 200
    super("")
  end

  def headers
    @headers.merge({
      "Content-Type" => self.content_type,
      "Content-Length" => self.size.to_s
    })
  end

  def render(file, context = nil)
    self << Erubis::FastEruby.new(File.read(file)).evaluate(context)
  end
end