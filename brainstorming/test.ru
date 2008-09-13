require "yaml"

app = lambda do |env|
  body = ["<pre>" + Rack::Request.new(env).to_yaml + "</pre>"]
  [
    200,
    {
      'Content-Type' => 'text/html',            # Reponse headers
      'Content-Length' => body.join.size.to_s
    },
    body
  ]
end

run app