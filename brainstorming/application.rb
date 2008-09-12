# config.ru

app = Application.new

app.route("/") do |request, response|
  response.puts "Hello World"
end

app.route "/users/show/:id" do |request, response|
  Users.new(request, response).show(params["id"])
end

run app

# Wieck::Authorization::routes.each do |matcher, handler|
#   app.route(matcher, &handler)
# end

# Application.rb

class Application

  def initialize
    @routes = Router.new
  end

  def call(env)
    # figure out what route we're at.
    response = Response.new
    request = Rake::Request.new(env)
    begin
      @routes.match(env).call(request, response)
    rescue
      if development?
        response.buffer.clear
        response.puts $!
        response.puts $!.backtrace
        response.puts request.to_yaml
      end
      response.status = 500
    end
    [response.status, response.headers, response.buffer]
  rescue
    [500, "", 0]
  end

  def route(matcher, &handler)
    @routes.register(matcher, &handler)
  end
end