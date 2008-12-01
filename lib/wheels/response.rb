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

      unless view.is_a?(View)
        layout = context.fetch(:layout, @request.layout)
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

    # 
    # Convenience methods from Rack::Response. We should be extending Rack::Response,
    # and not StringIO.
    # 

    def [](key)
      self.headers[key]
    end

    def []=(key, value)
      self.headers[key] = value
    end

    def set_cookie(key, value)
      case value
      when Hash
        domain  = "; domain="  + value[:domain]    if value[:domain]
        path    = "; path="    + value[:path]      if value[:path]
        # According to RFC 2109, we need dashes here.
        # N.B.: cgi.rb uses spaces...
        expires = "; expires=" + value[:expires].clone.gmtime.
          strftime("%a, %d-%b-%Y %H:%M:%S GMT")    if value[:expires]
        value = value[:value]
      end
      value = [value]  unless Array === value
      cookie = Rack::Utils.escape(key) + "=" +
        value.map { |v| Rack::Utils.escape v }.join("&") +
        "#{domain}#{path}#{expires}"

      case self["Set-Cookie"]
      when Array
        self["Set-Cookie"] << cookie
      when String
        self["Set-Cookie"] = [self["Set-Cookie"], cookie]
      when nil
        self["Set-Cookie"] = cookie
      end
    end

    def delete_cookie(key, value={})
      unless Array === self["Set-Cookie"]
        self["Set-Cookie"] = [self["Set-Cookie"]].compact
      end

      self["Set-Cookie"].reject! { |cookie|
        cookie =~ /\A#{Utils.escape(key)}=/
      }

      set_cookie(key,
                 {:value => '', :path => nil, :domain => nil,
                   :expires => Time.at(0) }.merge(value))
    end

  end
end