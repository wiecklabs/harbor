module Wheels
  ##
  # Extension to Rack's ShowExceptions middleware, displaying detailed error
  # messages in development, while sending error emails and friendly views
  # in other environments.
  # 
  # Your application should define a layout (default: layouts/exception.html.erb),
  # as well as friendly views for production (exceptions/404.html.erb, and 
  # exceptions/500.html.erb).
  # 
  #   use Wheels::Exception
  ##
  class Exception < Rack::ShowExceptions
    def initialize(app, layout = "layouts/exception")
      @app = app
      @environment = ENV["ENVIRONMENT"] || "development"
      @template = ERB.new(TEMPLATE) if development?
      @layout = layout
    end

    def call(env)
      result = @app.call(env)
      result[0] == 404 ? render_404(env) : result
    rescue StandardError, LoadError, SyntaxError => e
      if development?
        [500, {"Content-Type" => "text/html"}, pretty(env, e)]
      else
        trace = ""
        trace << "="*80
        trace << "\n"
        trace << "== [ #{e} @ #{Time.now} ] =="
        trace << "\n"
        trace << e.backtrace.join("\n")
        trace << "\n"
        trace << "== [ Request ] =="
        trace << "\n"
        trace << Rack::Request.new(env).env.to_yaml
        trace << "\n"
        trace << "="*80
        trace << "\n"

        # Add trace to log.
        puts trace

        m = Wheels::Mailer.new
        m.mail_server = Wheels::SendmailServer.new
        m.from = "exceptions@wieck.com"
        m.to = "dev@wieck.com"
        m.subject = "[ERROR] [#{ENV["USER"]}] [#{@environment}] #{e}"
        m.text = trace
        m.set_header("X-Priority", 1)
        m.set_header("X-MSMail-Priority", "High")
        m.send!

        [500, {"Content-Type" => "text/html"}, Wheels::View.new("exceptions/500.html.erb", :request => Wheels::Request.new(@app, env)).to_s(@layout)]
      end
    end

    def development?
      @environment == "development"
    end

    private
    def render_404(env)
      [404, {"Content-Type" => "text/html"}, Rack::Response.new(Wheels::View.new("exceptions/404.html.erb", :request => Wheels::Request.new(@app, env)).to_s(@layout), 404)]
    end
  end
end