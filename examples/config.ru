require "pathname"
require Pathname(__FILE__).dirname.parent + "lib/harbor"

class Foo < Harbor::Application
  class Bar < Harbor::Controller
    get "baz" do
      response.puts "Hello World!"
    end
    
    # get "/" do
    #   response.puts "I'm Home!"
    # end
  end
end

run Harbor