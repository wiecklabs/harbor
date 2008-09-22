require "stringio"
require Pathname(__FILE__).dirname + "view"

class Response < StringIO

  attr_accessor :status, :content_type, :headers

  def initialize
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

  def puts(content)
    raise ArgumentError.new("#{content.class} does not respond to #to_s") unless content.respond_to?(:to_s)
    raise ArgumentError.new("Views should be rendered with Response#render") if content.is_a?(View)
    super(content.to_s)
  end

  def render(view)
    raise ArgumentError.new("Objects passed to #render must response to #content_type.") unless view.respond_to?(:content_type)
    self.content_type = view.content_type
    self.puts(view.to_s)
  end

end