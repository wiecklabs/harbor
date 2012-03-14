module Harbor
  class Router
    module Helpers
      
      ###################
      # HTTP Verb Helpers
      ###################
      
      def get(path = "", &handler)
        route("GET", path, handler)
      end

      def post(path = "", &handler)
        route("POST", path, handler)
      end

      def put(path = "", &handler)
        route("PUT", path, handler)
      end

      # This conflicts with the CRUD helper defined below.
      # Leaving here just for explanation.
      #
      # def delete(path = "", &handler)
      #   route("DELETE", path, handler)
      # end

      def head(path = "", &handler)
        route("HEAD", path, handler)
      end

      def options(path = "", &handler)
        route("OPTIONS", path, handler)
      end

      def patch(path = "", &handler)
        route("PATCH", path, handler)
      end
      
      ############## 
      # CRUD Helpers
      ##############
      
      def index(&handler)
        route("GET", "", handler)
      end
      
      def show(&handler)
        route("GET", ":id", handler)
      end
      
      def create(&handler)
        route("POST", "", handler)
      end
      
      def update(&handler)
        route("PATCH", ":id", handler)
      end
      
      def delete(path = ":id", &handler)
        route("DELETE", path, handler)
      end
      
      def edit(&handler)
        route("GET", "edit/:id", handler)
      end
      
      ## Misc
      
      def redirect(source, destination)
        location = Harbor::Controller::NormalizedPath.new(self, destination)
        location = "/#{location}" unless location == "/"
        
        handler = lambda do
          response.status = 301
          response.headers["Location"] = location
          response.headers["Content-Type"] = "text/html"
          response.flush
          throw :abort_request
        end
        
        route("GET", source, handler)
      end
    end
  end
end