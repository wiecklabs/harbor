require_relative 'boot'

if RUBY_PLATFORM =~ /java/
  require_relative "../jetty"
else
  options = {
    :environment => config.environment,
    :pid         => nil,
    :Port        => 9292,
    :Host        => "0.0.0.0",
    :AccessLog   => [],
    :config      => "config.ru"
  }
  Rack::Server.start(options)
end
