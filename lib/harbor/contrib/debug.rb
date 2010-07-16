module Harbor
  module Contrib
    ##
    # USAGE:
    # Add the following code to your config.ru, just before 'run'
    #   if ENV['ENVIRONMENT'] == 'development'
    #     require "harbor/contrib/debug"
    #     DataObjects::Postgres.logger = Logging::Logger.root
    #     use Harbor::Contrib::Debug
    #   end
    ##
    class Debug
      def initialize(app)
        @app = app
        @levels = %w(DEBUG INFO WARN ERROR FATAL)
      end

      def call(env)
        start_time = Time.now
        status, headers, body = @app.call(env)
        load_time = Time.now - start_time

        appenders = Logging::Logger.root.instance_variable_get(:@appenders)
        logger = appenders.find { |appender| appender.name == "harbor_debug_messages" }
        messages = logger.messages.dup
        logger.messages.clear

        return [status, headers, body] unless (headers["Content-Type"] =~ /html/) && body.is_a?(String)

        debugger = @@template.dup

        if body["jquery"]
          debugger.gsub!("{{jquery}}", "")
        else
          debugger.gsub!("{{jquery}}", '<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.3.2/jquery.min.js"></script>')
        end

        debugger.gsub!("{{load_time}}", "%2.2f" % load_time)

        queries = messages.map do |level, message|
          ("<p>[#{@levels[level]}] " + message.gsub("<", "&lt;") + "</p>") if message =~ /^\(/
        end.compact

        messages = messages.map do |level, message|
          ("<p>[#{@levels[level]}] " + message.gsub("<", "&lt;") + "</p>") if message !~ /^\(/
        end.compact

        debugger.gsub!("{{query_count}}", "%s" % queries.size)
        debugger.gsub!("{{message_count}}", "%s" % messages.size)

        if messages.any?
          debugger.gsub!("{{messages}}", '<div class="messages" style="display: none">' + messages.join("\n") + '</div>')
        else
          debugger.gsub!("{{messages}}", "")
        end

        if queries.any?
          debugger.gsub!("{{queries}}", '<div class="queries" style="display: none">' + queries.join("\n") + '</div>')
        else
          debugger.gsub!("{{queries}}", "")
        end

        body.gsub!("</body>", debugger + "</body>")
        headers["Content-Length"] = body.length.to_s

        [status, headers, body]
      end

      class LogAppender < Logging::Appender
        def initialize
          @messages = []

          super("harbor_debug_messages", :level => :debug)
        end

        def messages
          @messages
        end

        def write(event)
          messages << [event.level, event.data]
        end
      end

      @@template = <<-HTML
{{jquery}}
<style type="text/css" media="screen">

  body:last-child { margin-bottom: 60px; }

  #logger {
    position: fixed; bottom: 0; font-family: "Lucida Grande"; z-index: 99000;
    width: 100%;
  }

  #logger ul {
    margin: 0; padding: 0; list-style: none; overflow: auto;
    width: 293px;
    margin: 0 auto;
    -webkit-border-top-right-radius: 5px;
    -webkit-border-top-left-radius: 5px;
    -moz-border-radius-topright: 5px;
    -moz-border-radius-topleft: 5px;
    -webkit-box-shadow: 0 0 10px #222;
    -moz-box-shadow: 0 0 10px #222;
  }

  #logger > div {
    -webkit-border-top-right-radius: 5px;
    -webkit-border-top-left-radius: 5px;
    -moz-border-radius-topright: 5px;
    -moz-border-radius-topleft: 5px;
    background-color: #222;
    padding: 10px;
    height: 200px;
    margin: 0 20px;
  }

  #logger > div div {
    overflow: auto;
    height: 200px;
  }

  #logger p { margin: 0; color: #eee; padding: 10px; line-height: 14px; font-size: 12px; font-family: monaco; border-bottom: 1px solid #555; }

  #logger ul li:first-of-type a {
    -webkit-border-top-left-radius: 5px;
    -moz-border-radius-topleft: 5px;
  }
  #logger ul li:last-of-type a {
    -webkit-border-top-right-radius: 5px;
    -moz-border-radius-topright: 5px;
  }

  #logger ul li { float: left; border-right: 1px solid #111; }
  #logger ul li:last-of-type { border: 0; }
  #logger ul li a {
    padding: 6px 10px; display: block; text-decoration: none; width: 77px; text-align: center; font-weight: bold;
    text-shadow: 1px 1px 1px #222; font-size: 14px; font-family: "Lucida Grande";
    line-height: 14px; border: 0;
  }
  #logger ul li a:hover, #logger ul li a.selected { text-shadow: 1px 1px 1px #444; }
  #logger ul li a span { display: block; font-size: 9px; line-height: 14px; text-transform: uppercase; text-align: center; }
  #logger .load_time a {
    color: #fff;
    background-color: #c62;
    background-image: -webkit-gradient(
      linear,
      left top,
      left bottom,
      color-stop(0.0, #e72),
      color-stop(0.5, #a62),
      color-stop(0.51, #a51)
    );
  }
  #logger .queries a {
    color: #fff;
    background-color: #248;
    background-image: -webkit-gradient(
      linear,
      left top,
      left bottom,
      color-stop(0.0, #47b),
      color-stop(0.5, #349),
      color-stop(0.51, #248)
    );
  }
  #logger .messages a {
    color: #fff;
    background-color: #482;
    background-image: -webkit-gradient(
      linear,
      left top,
      left bottom,
      color-stop(0.0, #7b4),
      color-stop(0.5, #493),
      color-stop(0.51, #482)
    );
  }
  {}
</style>

<div id="logger">
  <ul>
    <li class="load_time"><a href="#">{{load_time}}<span>seconds</span></a></li>
    <li class="queries"><a href="#">{{query_count}}<span>queries</span></a></li>
    <li class="messages"><a href="#">{{message_count}}<span>messages</span></a></li>
  </ul>

  <div style="display: none">
    {{queries}}
    {{messages}}
  </div>
</div>

</div>
<script type="text/javascript" charset="utf-8">
  var _body = document.body;
  var _html = JQuery("html").get(0);
  JQuery(window).keyup(function(event) {
    if ( event.which == 76 && (event.target == _body || event.target == _html) ) {
      JQuery("#logger").slideToggle();
    }
  });
  JQuery("#logger li a").click(function() {
    var info = JQuery("#logger div." + JQuery(this).parent().attr("class"));
    if ( info.get(0) ) {
      if ( (siblings = info.siblings("div:visible")).get(0) ) {
        siblings.hide();          
        info.toggle();
      }
      else {
        if ( info.css("display") == "block" ) {
          JQuery("#logger > div").slideToggle(function() {
            info.hide();
          });
        }
        else {
          info.show();
          JQuery("#logger > div").slideToggle();
        }
      }
    }
    else {
      JQuery("#logger > div:visible").slideToggle(function() {
        JQuery("#logger > div div").hide();
      });
    }
    return false;
  });
</script>
HTML
    end
  end
end

Logging::Logger.root.add_appenders(Harbor::Contrib::Debug::LogAppender.new)
