require "pathname"
require Pathname(__FILE__).dirname.parent + "lib/harbor"

class Foo < Harbor::Application
  class Bar < Harbor::Controller
    
    # GET: /bar/baz
    get "baz" do
      response.puts "Hello World!"
    end

    # GET: /baz
    get "/baz" do
      response.puts "One of these is not like the other..."
    end
    
    # GET: /bar
    get do
      response.puts "It's all relative baby!"
    end
    
    # GET: /
    get "/" do
      response.puts "I'm Home!"
    end
    
    get "baz/:zed" do |zed|
      response.puts "WILDCARD!: #{zed}"
    end
    
    get "/categories/:category_id/posts/:post_id" do |category_id, post_id|
      response.puts "Looking for #{post_id} in #{category_id}..."
    end
  end
end

run Harbor