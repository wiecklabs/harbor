if ::File.exists? "lib/boot.rb"
  require "lib/boot"
else
  STDERR.puts "harbor console must be run from your application's root!"
  exit 1
end

config.console.start