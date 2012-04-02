if ::File.exists? "lib/boot.rb"
  require "lib/boot"
else
  STDERR.puts "harbor server must be run from your application's root!"
  exit 1
end

if RUBY_PLATFORM =~ /java/
  require_relative "../jetty"
else
  Rack::Server.start(Port: 9292, config: "config.ru", environment: ENV["ENVIRONMENT"])
end