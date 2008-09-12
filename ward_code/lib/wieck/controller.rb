class Wieck
  class Controllers
    class Base
      
      attr_accessor :request, :response, :view, :layout
      
      def initialize(request, response)
        @request = request
        @response = response
      end      
      
      # Shortcut to @response.write
      def puts(data)
        @response.write(data)
      end
      
      # Shorcut to @response.render
      def render
        @response.render
      end
      
    end
  end
end