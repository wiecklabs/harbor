require "pathname"
require Pathname(__FILE__).dirname.parent + "lib/router"

router = Router.new do
  get("/") { "Hello World" }
end

app = lambda do |env|
  response = router.match(Rack::Request.new(env)).call
  [
    200,
    {
      "Content-Type" => "text/plain",
      "Content-Length" => response.size.to_s
    },
    [response]
  ]
end

run app