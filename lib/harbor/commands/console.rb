if ::File.exists? "lib/boot.rb"
  require "lib/boot"
else
  STDERR.puts "harbor console must be run from your application's root!"
  exit 1
end

require "irb"

begin
  require "irb/completion"
rescue Exception
  # No readline available, proceed anyway.
end

if ::File.exists? ".irbrc"
  ENV['IRBRC'] = ".irbrc"
end