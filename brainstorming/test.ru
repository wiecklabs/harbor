require "pathname"
require Pathname(__FILE__).dirname.parent + "lib/framework"

router = Router.new do
  get("/") { |request, response| response.puts "Hello World" }
end

run Application.new(router)