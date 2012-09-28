require "pathname"
require Pathname(__FILE__).dirname.parent + "lib/harbor"

router = Harbor::Router.new do
  get("/") { |request, response| response.puts "Hello World" }
end

run Harbor::Application.new(Harbor::Container.new, router)