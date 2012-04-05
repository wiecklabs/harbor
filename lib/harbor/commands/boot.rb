if ::File.exists? "./lib/boot.rb"
  require "./lib/boot"
else
  STDERR.puts "harbor #{ARGV.first} must be run from your application's root!"
  exit 1
end
