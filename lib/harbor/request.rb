require "rack/request"
require_relative "session"

class Harbor
  class Request < Rack::Request

    BOT_AGENTS = [
      /yahoo.*slurp/i,
      /googlebot/i,
      /msnbot/i,
      /charlotte.*searchme/i,
      /twiceler.*robot/i,
      /dotbot/i,
      /gigabot/i,
      /yanga.*bot/i,
      /gaisbot/i,
      /becomebot/i,
      /yandex/i,
      /catchbot/i,
      /cazoodlebot/i,
      /jumblebot/i,
      /librabot/i,
      /jyxobot/i,
      /mlbot/i,
      /cipinetbot/i,
      /funnelbot/i,
      /mj12bot/i,
      /spinn3r/i,
      /nutch.*bot/i,
      /oozbot/i,
      /robotgenius/i,
      /snapbot/i,
      /tmangobot/i,
      /yacybot/i,
      /rpt.*httpclient/i,
      /indy.*library/i,
      /baiduspider/i,
      /WhistleBlower/i,
      /Pingdom/
    ].freeze

    attr_accessor :layout

    def initialize(application, env)
      raise ArgumentError.new("+env+ must be a Hash") unless env.is_a?(Hash)
      @application = application
      super(env)
    end

    def fetch(key, default_value = nil)
      if (value = self[key]).nil? || value == ''
        default_value
      else
        value
      end
    end

    def bot?
      user_agent = env["HTTP_USER_AGENT"]
      BOT_AGENTS.any? { |bot_agent| user_agent =~ bot_agent }
    end

    def unload_session
      @session = nil
    end

    def session(key = nil)
      @session ||= Harbor::Session.new(self, key)
    end

    def session?
      @session
    end

    def remote_ip
      # handling proxied environments
      env["HTTP_X_FORWARDED_FOR"] || env["HTTP_CLIENT_IP"] || env["REMOTE_ADDR"]
    end

    def request_method
      @env['REQUEST_METHOD'] = self.POST['_method'].upcase if request_method_in_params?
      @env['REQUEST_METHOD']
    end

    def health_check?
      !params["health_check"].nil?
    end

    def params
      params = begin
        if @env["rack.input"].nil?
          self.GET
        else
          self.GET && self.GET.update(self.POST || {})
        end
      rescue EOFError => e
        self.GET
      end

      params || {}
    end

    def protocol
      ssl? ? 'https://' : 'http://'
    end

    def ssl?
      @env['HTTPS'] == 'on' || @env['HTTP_X_FORWARDED_PROTO'] == 'https'
    end

    def referer
      @env['HTTP_REFERER']
    end

    def uri
      @env['REQUEST_URI'] || @env['REQUEST_PATH'] || @env['PATH_INFO']
    end

    def messages
      @messages ||= session[:messages] = Messages.new(session[:messages])
    end

    def message(key)
      messages[key]
    end

    # ==== Returns
    # String::
    #   The URI without the query string. Strips trailing "/" and reduces
    #   duplicate "/" to a single "/".
    def path
      path = (uri.empty? ? '/' : uri.split('?').first).squeeze("/")
      path = path[0..-2] if (path[-1] == ?/) && path.size > 1
      path
    end

    def accept
      @accept ||= begin
        entries = @env['HTTP_ACCEPT'].to_s.split(',')
        entries.map! { |e| accept_entry(e) }
        entries.sort_by! { |e| [e.last, entries.index(e)] }
        entries.map(&:first)
      end
    end

    def preferred_type(*types)
      return accept.first if types.empty?
      types.flatten!
      accept.detect do |pattern|
        type = types.detect { |t| ::File.fnmatch(pattern, t) }
        return type if type
      end
    end

    # Returns the extension for the format used in the request.
    #
    # GET /posts/5.xml | request.format => xml
    # GET /posts/5.js | request.format => js
    # GET /posts/5 | request.format => request.accepts.first
    #
    def format
      formats.first
    end

    def format=(format)
      params['format'] = format
      @formats = [format]
    end

    BROWSER_LIKE_ACCEPTS = /,\s*\*\/\*|\*\/\*\s*,/

    def formats
      @formats ||= begin
        http_accept = @env['HTTP_ACCEPT']

        accepted_formats = if params['format']
          Array(params['format'])
        elsif xhr? || (http_accept && http_accept !~ BROWSER_LIKE_ACCEPTS)
          # TODO: Mime types could be objects
          accept.map{|type| Mime.extension(type).to_s.gsub(/^\./, '')}
        else
          ['html']
        end

        accepted_formats == ['all'] ? ['html'] : accepted_formats
      end
    end

    private

    def accept_entry(entry)
      type, *options = entry.delete(' ').split(';')
      quality = 0 # we sort smallest first
      options.delete_if { |e| quality = 1 - e[2..-1].to_f if e.start_with? 'q=' }
      [type, [quality, type.count('*'), 1 - options.size]]
    end

    def request_method_in_params?
      @env["REQUEST_METHOD"] == "POST" && self.POST && %w(PUT DELETE).include?((self.POST['_method'] || "").upcase)
    end
  end
end
