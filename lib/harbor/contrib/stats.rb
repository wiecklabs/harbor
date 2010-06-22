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

    end
  end
end

Harbor::Application.register_event_handler(:request_complete) do |event|
  request = event.request
  response = event.response
  if orm = Harbor::Contrib::Stats.orm
    if request.session?
      session = request.session

      # We only record a PageView if we get a 200 and it's an actual page rendering, not providing an image or downloading a file
      orm::PageView.create(session.id, request.uri, request.referrer) if %w(text/html text/xml text/json).include?(response.content_type) && response.status == 200
      orm::UserAgent.create(session.id, request.remote_ip, request.env["HTTP_USER_AGENT"])
    end
  else    
    warn "Harbor::Contrib::Stats::orm must be set to generate statistics."
  end
end
