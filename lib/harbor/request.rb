require "rack/request"
require_relative "session"

module Harbor
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
      raise ArgumentError.new("+env+ must be a Rack Environment Hash") unless env.is_a?(Hash)
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

    # holdover method until Harbor::Router moves to oniguruma and can use named captures
    def route_captures
      @route_captures || []
    end

    def route_captures=(value)
      @route_captures = value
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

    private
    def request_method_in_params?
      @env["REQUEST_METHOD"] == "POST" && self.POST && %w(PUT DELETE).include?((self.POST['_method'] || "").upcase)
    end
  end
end
