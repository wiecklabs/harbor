require "rubygems"
require "pathname"

require Pathname(__FILE__).dirname.parent.parent + "lib/harbor"
require Pathname(__FILE__).dirname + "controllers/hello"

View::path.unshift Pathname(__FILE__).dirname + "views"

response = Response.new
hello = Hello.new({}, response)
hello.usa

puts response.inspect