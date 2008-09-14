require "pathname"
require Pathname(__FILE__).dirname.parent + "lib/framework"

class Hello
  attr_reader :request, :response
  
  def initialize(request, response)
    @request = request
    @response = response
  end
  
  def world
    response.puts "Hello World"
  end
end

router = Router.new do
  get("/") do |request, response|
    Hello.new(request, response).world
  end
end

run Application.new(router)