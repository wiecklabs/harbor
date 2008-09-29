require "rubygems"
require "pathname"

require Pathname(__FILE__).dirname.parent.parent + "lib/wheels"
require Pathname(__FILE__).dirname + "controllers/hello"

View::path.unshift Pathname(__FILE__).dirname + "views"

response = Response.new
hello = Hello.new({}, response)
hello.usa

puts response.inspect