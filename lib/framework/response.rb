require "stringio"
require "lib/framework/view"

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
    raise ArgumentError.new("+view+ must be a View but was a #{view.class}") unless view.is_a?(View)
    self.content_type = view.content_type
    super(view.to_s)
  end

end