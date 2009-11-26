require "rack/request"
require Pathname(__FILE__).dirname + "session"

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
    attr_accessor :application

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

    def session
      @session ||= Harbor::Session.new(self)
    end

    def session?
      @session
    end

    def remote_ip
      env["REMOTE_ADDR"] || env["HTTP_CLIENT_IP"] || env["HTTP_X_FORWARDED_FOR"]
    end

    def request_method
      @env['REQUEST_METHOD'] = self.POST['_method'].upcase if request_method_in_params?
      @env['REQUEST_METHOD']
    end

    def environment
      @env['APP_ENVIRONMENT'] || (@application ? @application.environment : "development")
    end

    def params
      params = begin
        self.GET && self.GET.update(self.POST || {})
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
      @env['REQUEST_URI'] || @env['REQUEST_PATH']
    end

    def messages
      @messages ||= if session?
        session[:messages] = Messages.new((session[:messages]||{}).merge(params["messages"]||{}))
      else
        params["messages"] = Messages.new(params["messages"])
      end
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