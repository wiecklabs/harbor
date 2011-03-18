module Harbor
  module Contrib
    class Stats

      require Pathname(__FILE__).dirname.expand_path + "stats/models/user_agent"
      require Pathname(__FILE__).dirname.expand_path + "stats/models/page_view"

      def self.orm=(orm)
        require Pathname(__FILE__).dirname.expand_path + "stats/orm/#{orm}"

        @orm = const_get(orm.gsub(/(^|_)(.)/) { $2.upcase })
      end

      def self.orm
        @orm
      end
      
      def self.denied_ips
        @@denied_ips ||= []
      end
      
      def self.denied_ips=(ips)
        @@denied_ips = ips
      end
      
      def self.known_bots
        @@bots ||= [
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
          /Pingdom/,
          /discobot/i,
          /charlotte.*searchme/i,
          /speedy spider/i,
          /psbot/
        ]
      end
      
      def self.known_bots=(bots)
        @@bots = bots
      end
      
      def self.denied_user?(remote_ip, user_agent)
        known_bots.any? { |bot| user_agent =~ bot } || denied_ips.include?(remote_ip)
      end

    end
  end
end

Harbor::Session.register_event_handler(:session_created) do |event|
  if orm = Harbor::Contrib::Stats.orm
    orm::UserAgent.create(event.session_id, event.remote_ip, event.user_agent) unless Harbor::Contrib::Stats.denied_user?(event.remote_ip, event.user_agent)
  else    
    warn "Harbor::Contrib::Stats::orm must be set to generate statistics."
  end
end

Harbor::Application.register_event_handler(:request_complete) do |event|
  request = event.request
  response = event.response
  if orm = Harbor::Contrib::Stats.orm
    if request.session?
      session = request.session

      # We only record a PageView if we get a 200 and it's an actual page rendering, not providing an image or downloading a file
      unless Harbor::Contrib::Stats.denied_user?(request.ip, request.env["HTTP_USER_AGENT"])
        orm::PageView.create(session.id, request.uri, request.referrer) if %w(text/html text/xml text/json).include?(response.content_type) && response.status == 200 && request.health_check? == false
      end
    end
  else    
    warn "Harbor::Contrib::Stats::orm must be set to generate statistics."
  end
end