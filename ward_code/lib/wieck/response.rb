class Wieck
  class Response
    
    attr_accessor :status, :headers, :body, :output, :rendered
    
    # Constructor
    def initialize(env)
      @status = 200
      @headers = {"Content-Type" =>  "text/html"}
      @body = []
    end
        
    # Add header to response list
    def add_header(header_name, header_value)
      #@headers[header_name] = header_value
    end
    
    # Write to output buffer
    def write(data)
      @body << data
    end
    
    def test
      return "asdf"
    end
    
    # Render output
    def render
      @rendered = true
      @output = [@status, @headers, @body]
    end
    
    # Render blank page
    def render_nothing
      @output = [200, {"Content-Type" => "text/html"}, ""]
    end
    
  end
end