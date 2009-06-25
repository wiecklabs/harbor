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

    def layout
      defined?(@layout) ? @layout : application.default_layout
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

    private
    def request_method_in_params?
      @env["REQUEST_METHOD"] == "POST" && self.POST && %w(PUT DELETE).include?((self.POST['_method'] || "").upcase)
    end
  end
end