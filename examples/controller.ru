require "pathname"
require Pathname(__FILE__).dirname.parent + "lib/harbor"

services = Harbor::Container.new
# services.register("mail_server", Harbor::SmtpServer.new)
# services.register("mailer", Harbor::Mailer)

class Hello
  attr_accessor :request, :response

  def world
    response.puts "Hello World"
  end
end

router = Harbor::Router.new do
  using services, Hello do
    get("/") do |hello|
      hello.world
    end
  end
end

run Harbor::Application.new(router)