require_relative 'boot'

if RUBY_PLATFORM =~ /java/
  require_relative "../jetty"
else
  Rack::Server.start(Port: 9292, config: "config.ru", environment: ENV["ENVIRONMENT"])
end
