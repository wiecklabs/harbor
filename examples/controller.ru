require "pathname"
require Pathname(__FILE__).dirname.parent + "lib/wheels"

services = Wheels::Container.new
# services.register("mail_server", Wheels::SmtpServer.new)
# services.register("mailer", Wheels::Mailer)

class Hello
  attr_accessor :request, :response

  def world
    response.puts "Hello World"
  end
end

router = Wheels::Router.new do
  using services, Hello do
    get("/") do |hello|
      hello.world
    end
  end
end

run Wheels::Application.new(router)