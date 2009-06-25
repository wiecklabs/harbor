require "stringio"
require Pathname(__FILE__).dirname + "view"

module Harbor
  class Response

    attr_accessor :status, :content_type, :headers

    def initialize(request)
      @request = request
      @headers = {}
      @content_type = "text/html"
      @status = 200
    end

    def headers
      @headers.merge!({
        "Content-Type" => self.content_type,
        "Content-Length" => self.size.to_s
      })
      @headers
    end

    def flush
      @io = nil
    end

    def size
      buffer.size
    end

    def puts(value)
      string.puts(value)
    end

    def print(value)
      string.print(value)
    end

    def buffer
      if @io.is_a?(StringIO)
        @io.string
      else
        @io || ""
      end
    end

    def stream_file(path_or_io, content_type = nil)
      if path_or_io.is_a?(StringIO) || path_or_io.is_a?(::IO)
        @io = BlockIO.new(path_or_io)
        @headers["Content-Length"] = @io.size
      else
        content_type ||= Rack::File::MIME_TYPES.fetch(::File.extname(path_or_io)[1..-1], "binary/octet-stream")
        if @request.env.has_key?("HTTP_X_SENDFILE_TYPE")
          @headers["X-Sendfile"] = path_or_io.to_s
          @headers["Content-Length"] = ::File.size(path_or_io)
        else
          @io = BlockIO.new(path_or_io)
          @headers["Content-Length"] = @io.size
        end
      end

      @content_type = content_type
      nil
    end

    def send_file(name, path_or_io, content_type = nil)
      stream_file(path_or_io, content_type)

      @headers["Content-Disposition"] = "attachment; filename=\"#{escape_filename_for_http_header(name)}\""
      nil
    end

    def render(view, context = {})

      layout = nil

      unless view.is_a?(View)
        layout = context[:layout]
        layout ||= @request.layout unless @request.xhr?
        view = View.new(view, context.merge({ :request => @request }))
      end

      self.content_type = view.content_type
      puts view.to_s(layout)
    end

    def redirect(url, params = nil)
      self.status = 303
      self.headers = { "Location" => (params ? "#{url}?#{Rack::Utils::build_query(params)}" : url) }
      self.flush
      self
    end

    def redirect!(url, params = nil)
      redirect(url, params) and throw(:abort_request)
    end

    def abort!(code)
      self.status = code
      throw(:abort_request)
    end

    def unauthorized
      self.status = 401
    end

    def unauthorized!
      unauthorized and throw(:abort_request)
    end

    def inspect
      "<#{self.class} headers=#{headers.inspect} content_type=#{content_type.inspect} status=#{status.inspect} body=#{buffer.inspect}>"
    end

    def to_a
      if @request.session?
        session = @request.session
        set_cookie(session.key, session.save)
      end

      [self.status, self.headers, self.buffer]
    end

    def [](key)
      headers[key]
    end

    def []=(key, value)
      headers[key] = value
    end

    def set_cookie(key, value)
      raise ArgumentError.new("+key+ must not be blank") if key.nil? || key.size == 0

      case value
      when Hash
        domain    = "; domain="  + value[:domain]    if value[:domain]
        path      = "; path="    + value[:path]      if value[:path]
        http_only = value[:http_only] ? "; HTTPOnly=" : nil
        # According to RFC 2109, we need dashes here.
        # N.B.: cgi.rb uses spaces...
        expires_on = if (defined?(DateTime) && value[:expires].is_a?(DateTime))
          value[:expires].clone.new_offset(0)
        elsif value[:expires].is_a?(Time)
          value[:expires].clone.gmtime
        elsif value[:expires].nil?
          nil
        else
          raise ArgumentError.new("The value hash for set_cookie contains an invalid +expires+ attribute, Time or DateTime expected, but got: #{value[:expires].inspect}")
        end
        expires = "; expires=" + expires_on.strftime("%a, %d-%b-%Y %H:%M:%S GMT") if expires_on

        value = value[:value]
      end
      value = [value]  unless Array === value
      cookie = Rack::Utils.escape(key) + "=" +
        value.map { |v| Rack::Utils.escape v }.join("&") +
        "#{domain}#{path}#{expires}#{http_only}"

      case self["Set-Cookie"]
      when Array
        self["Set-Cookie"] << cookie
      when String
        self["Set-Cookie"] = [self["Set-Cookie"], cookie]
      when nil
        self["Set-Cookie"] = cookie
      end
    end

    private

    def string
      @io ||= StringIO.new("")
    end

    # 
    def escape_filename_for_http_header(filename)
      # This would work great if IE6 could unescape the Content-Disposition filename field properly,
      # but it can't, so we use the terribly weak version instead, until IE6 dies off...
      #filename.gsub(/["\\\x0]/,'\\\\\0')

      filename.gsub(/[^\w\.]/, '_')
    end

  end
end