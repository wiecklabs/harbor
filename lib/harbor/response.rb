require "stringio"
require_relative "view"

java_import java.net.URLEncoder

class Harbor
  class Response
    
    ENCODED_CHARSET = "UTF-8"
    
    attr_accessor :status, :headers, :errors

    class UnsupportedSendfileTypeError < StandardError
      def initialize(header)
        super("An unsupported HTTP_X_SENDFILE_TYPE header was found: #{header}")
      end
    end

    def initialize(request)
      @request = request
      @headers = {}
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
      content_type = Mime.mime_type(".#{content_type}", 'text/html') if content_type.is_a?(Symbol) || content_type !~ /\//
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
        @io
      else
        @io || StringIO.new
      end
    end

    # Required to allow Rack apps to set the response from outside
    def buffer=(buffer)
      @io = buffer
    end

    def buffer_string
      if @io.is_a?(StringIO)
        @io.string
      else
        @io || ""
      end
    end

    def stream_file(path_or_io, content_type = nil)
      io = BlockIO.new(path_or_io)

      if io.path && (header = @request.env["HTTP_X_SENDFILE_TYPE"])
        case header
        when "X-Sendfile"
          @headers["X-Sendfile"] = io.path
        when "X-Accel-Redirect"
          if mapping = @request.env['HTTP_X_ACCEL_MAPPING']
            internal, external = mapping.split('=', 2).map { |p| p.strip }
            @headers["X-Accel-Redirect"] = io.path.sub(/^#{Regexp::escape(internal)}/i, external)
          else
            @headers["X-Accel-Redirect"] = io.path
          end
        else
          raise UnsupportedSendfileTypeError.new(header)
        end
      else
        @io = io
      end

      self.size = io.size
      self.content_type = content_type || Harbor::Mime.mime_type(::File.extname(io.path.to_s))
      nil
    end

    def send_file(name, path_or_io, content_type = nil)
      stream_file(path_or_io, content_type)

      @headers["Content-Disposition"] = "attachment; filename=\"#{escape_filename_for_http_header(name)}\""
      nil
    end

    ##
    #
    # Harbor::Response#send_files
    #
    #   name:     filename presented to the browser for the download
    #   files:    Enumerable of Harbor::File instances.  The files are expected to
    #             exist on disk.
    #
    # If Nginx sends a HTTP_MOD_ZIP_ENABLED header, build a list of files compatible
    # with the format specified @ https://github.com/evanmiller/mod_zip:
    #
    #    1034ab38 428    /foo.txt   My Document1.txt
    #    83e8110b 100339 /bar.txt   My Other Document1.txt
    #
    # Where the components are, in order: CRC32 (in hexadecimal), uncompressed file size, path or
    # URL to file that can be found by Nginx, and filename (with optional relative path information
    # to be used when building the zip file).  The mod_zip documentation claims that the CRC32 is
    # optional, but in practice, zip files generated w/out the CRC value on Ubuntu won't open on
    # at least Mac OSX 10.6.
    #
    # If no HTTP_MOD_ZIP_ENABLED is sent, use the ZippedIO class to generate the zip file.  This is extremely
    # inefficient and should never be used in a produciton environment.
    #
    ##
    def send_files(name, files)
      if @request.env["HTTP_MOD_ZIP_ENABLED"]
        filenames = []
        files.each do |file|
          path = ::File.expand_path(file.path)
          filename = file.name
          while filenames.include? filename
            extname = ::File.extname(filename)
            basename = ::File.basename(filename, extname)
            if basename =~ /-(\d+)$/
              counter = $1.to_i + 1
            else
              counter = 2
            end
            filename = "#{basename}-#{counter}#{extname}"
          end
          filenames << filename
          if file.respond_to?(:checksum)
            puts("#{file.checksum(:pkzip)} #{::File.size(path)} #{path} #{filename}")
          else
            puts("#{Harbor::File.new(path).checksum(:pkzip)} #{::File.size(path)} #{path} #{filename}")
          end
        end
        headers["X-Archive-Files"] = "zip"
        self.content_type = "application/zip"
        @headers["Content-Disposition"] = "attachment; filename=\"#{escape_filename_for_http_header(name)}\""
      else
        @io = ZippedIO.new(files)
        self.size = @io.size
        self.content_type = "application/zip"
        @headers["Content-Disposition"] = "attachment; filename=\"#{escape_filename_for_http_header(name)}\""
      end
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
        return puts(item.content) unless item.content.nil?
      end

      yield self
      store.put(key, buffer_string, ttl, max_age) if store
    end

    def render(view, context = {})
      context = context.merge({ :request => @request, :response => self, :format => @request.format })
      view = View.new(view, context)

      layout = context.fetch(:layout) do
        (@request.xhr? || context[:format] != 'html') ?
          nil :
          :search
      end
      puts view.to_s(layout)
      self.content_type ||= @request.format
    end

    HEADER_BLACKLIST = ['X-Sendfile', "Content-Disposition"]
    def redirect(url, params = nil)
      url = URI.parse(url)
      params ||= {}

      if url.query
        params.merge!(Rack::Utils.parse_query(url.query))
        url.query = nil
      end

      if @request && !@request.session? && !messages.empty? && !messages.expired?
        messages.each { |key, value| params["messages[#{key}]"] = value }
      end

      url.query = Rack::Utils::build_query(params) if params && params.any?

      self.status = 303
      self.headers.merge!({
        "Location" => url.to_s,
        "Content-Type" => "text/html"
      })
      HEADER_BLACKLIST.each{|banned_header| self.headers.delete(banned_header)}
      self.flush
      self
    end

    def redirect!(url, params = nil)
      redirect(url, params) and throw(:halt)
    end

    def abort!(code)
      if Harbor::View.exists?("exceptions/#{code}.html.erb")
        render "exceptions/#{code}.html.erb"
      end

      self.status = code
      throw(:halt)
    end

    def unauthorized
      self.status = 401
    end

    def unauthorized!
      abort!(401)
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
      throw(:halt)
    end

    def inspect
      "<#{self.class} headers=#{headers.inspect} content_type=#{content_type.inspect} status=#{status.inspect} body=#{buffer.inspect}>"
    end

    def messages
      @messages ||= @request.messages
    end

    ##
    # Calling reponse.message forces a session to load. The reasoning is as follows:
    # 1) This will eliminate the majority of ugly query-string messages.
    # 2) Calling response.message in an action assumes a human receiver and thus the
    #    use of a session is valid
    #
    # Nonetheless, control is left to app. Use use_session = false to use query-string
    # based messages instead.
    ##
    def message(key, message, use_session=true)
      @request.session if use_session
      messages[key] = message
    end

    def to_a
      messages.clear if messages.expired?

      if @request.session?
        session = @request.session
        set_cookie(session.key, session.save)
      end

      self.content_type ||= "html" unless self.status == 304
      # headers cannot be arrays
      self.headers.each_pair do |key, value|
        self.headers[key] = value.join("\n") if value.is_a?(Array)
      end

      self.buffer.rewind if self.buffer.respond_to?(:rewind)

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

        #   According to http://curl.haxx.se/rfc/cookie_spec.html, some browsers have issues when setting
        # expire property without setting path, look under expire notes on that link
        if value[:path]
          path      = "; path="    + value[:path]
        elsif value[:expires]
          path      = "; path=/"
        end


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
      cookie = URLEncoder.encode(key, ENCODED_CHARSET) + "=" +
        value.map { |v| URLEncoder.encode v, ENCODED_CHARSET }.join("&") +
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

    def delete_cookie(key, value={})
      unless Array === self["Set-Cookie"]
        self["Set-Cookie"] = [self["Set-Cookie"]].compact
      end

      self["Set-Cookie"].reject! { |cookie|
        cookie =~ /\A#{URLEncoder.encode(key, ENCODED_CHARSET)}=/
      }

      set_cookie(key,
                 {:value => '', :path => nil, :domain => nil,
                   :expires => Time.at(0) }.merge(value))
    end

    def status=(new_status)
      @status = new_status
      if @status == 204 || @status == 304
        @headers.delete "Content-Type"
        @headers.delete "Content-Length"
        string.truncate(0)
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
