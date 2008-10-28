require "stringio"
require Pathname(__FILE__).dirname + "view"

module Wheels
  class Response < StringIO

    attr_accessor :status, :content_type, :headers

    def initialize(request)
      @request = request
      @headers = {}
      @content_type = "text/html"
      @status = 200
      super("")
    end

    def headers
      @headers.merge!({
        "Content-Type" => self.content_type,
        "Content-Length" => self.size.to_s
      })
      @headers
    end

    def render(view, context = {})

      layout = nil
      default_layout = @request.application.default_layout if @request.application.respond_to?(:default_layout)

      unless view.is_a?(View)
        layout = context.fetch(:layout, default_layout)
        view = View.new(view, context.merge({ :request => @request }))
      end

      self.content_type = view.content_type
      puts view.to_s(layout)
    end

    def redirect(url, params = nil)
      self.status = 303
      self.headers = { "Location" => (params ? "#{url}?#{Rack::Utils::build_query(params)}" : url) }
      self.string = ""
      self
    end

    def inspect
      "<#{self.class} headers=#{headers.inspect} content_type=#{content_type.inspect} status=#{status.inspect} body=#{string.inspect}>"
    end

  end
end