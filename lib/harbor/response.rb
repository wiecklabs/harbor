require "stringio"
require Pathname(__FILE__).dirname + "view"

module Harbor
  class Response

    attr_accessor :status, :headers, :errors

    def initialize(request)
      @request = request
      @headers = {}
      @headers["Content-Type"] = "text/html"
      @status = 200
      @errors = Harbor::Errors.new
    end

    def headers
      @headers
    end

    def flush
      @io = nil
    end

    def size=(size)
      @headers["Content-Length"] = size.to_s
    end

    def size
      (@headers["Content-Length"] || buffer.size).to_i
    end

    def content_type=(content_type)
      @headers["Content-Type"] = content_type
    end

    def content_type
      @headers["Content-Type"]
    end

    def puts(value)
      string.puts(value)
      self.size = string.length
    end

    def print(value)
      string.print(value)
      self.size = string.length
    end

    def buffer
      if @io.is_a?(StringIO)
        @io.string
      else
        @io || ""
      end
    end

    def stream_file(path_or_io, content_type = nil)
      io = BlockIO.new(path_or_io)
      content_type ||= Harbor::Mime.mime_type(::File.extname(io.path.to_s))

      if io.path && @request.env.has_key?("HTTP_X_SENDFILE_TYPE")
        @headers["X-Sendfile"] = io.path
      else
        @io = io
      end
     
      self.size = io.size
      self.content_type = content_type
      nil
    end

    def send_file(name, path_or_io, content_type = nil)
      stream_file(path_or_io, content_type)

      @headers["Content-Disposition"] = "attachment; filename=\"#{escape_filename_for_http_header(name)}\""
      nil
    end

    def cache(key, last_modified, ttl = nil, max_age = nil)
      raise ArgumentError.new("You must provide a block of code to cache.") unless block_given?

      store = nil
      if key && (ttl || max_age)
        store = Harbor::View.cache

        unless store
          raise ArgumentError.new("Cache Store Not Defined. Please set Harbor::View.cache to your desired cache store.")
        end

        key = "page-#{key}"
      end

      last_modified = last_modified.httpdate
      @headers["Last-Modified"] = last_modified
      @headers["Cache-Control"] = "max-age=#{ttl}, must-revalidate" if ttl

      modified_since = @request.env["HTTP_IF_MODIFIED_SINCE"]

      if modified_since == last_modified && (!store || store.get(key))
        not_modified!
      elsif store && item = store.get(key)
        return puts(item.content)
      end

      yield self
      store.put(key, buffer, ttl, max_age) if store
    end

    # Headers that MUST NOT be included with 304 Not Modified responses.
    #
    # http://tools.ietf.org/html/rfc2616#section-10.3.5
    NOT_MODIFIED_OMIT_HEADERS = %w[
      Allow
      Content-Encoding
      Content-Language
      Content-Length
      Content-MD5
      Content-Type
      Last-Modified
    ].to_set

    def not_modified!
      NOT_MODIFIED_OMIT_HEADERS.each { |name| headers.delete(name) }
      self.status = 304
      throw(:abort_request)
    end

    def render(view, context = {})
      if context[:layout].is_a?(Array)
        warn "Passing multiple layouts to response.render has been deprecated. See Harbor::Layouts."
        context[:layout] = context[:layout].first
      end

      case view
      when View
        view.context.merge(context)
      else
        view = View.new(view, context.merge({ :request => @request, :response => self }))
      end

      self.content_type = view.content_type

      if context.has_key?(:layout) || @request.xhr?
        puts view.to_s(context[:layout])
      else
        puts view.to_s(:search)
      end
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
      if Harbor::View.exists?("exceptions/#{code}.html.erb")
        render "exceptions/#{code}.html.erb"
      end

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
