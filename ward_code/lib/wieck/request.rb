class Wieck
  class Request
    
    attr_accessor :method, :domain, :uri
    
    # Constructor
    def initialize(env)
      r = Rack::Request.new(env)
    end
    
  end
end