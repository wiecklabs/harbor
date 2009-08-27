require "rubygems"
require "pathname"

require Pathname(__FILE__).dirname.parent.parent + "lib/harbor"
require Pathname(__FILE__).dirname + "controllers/hello"

Harbor::View::path.unshift Pathname(__FILE__).dirname + "views"

class ViewExample < Harbor::Application
  def self.routes(services)
    Harbor::Router.new do
      using services, Hello do
        get("/") { |hello| hello.world }
        get("/usa") { |hello| hello.usa }
      end
    end
  end
end

run ViewExample.new(Harbor::Container.new)