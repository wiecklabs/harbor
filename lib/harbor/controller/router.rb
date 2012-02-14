require "set"
require "harbor/controller/router/route"

module Harbor
  class Controller
    class Router
      
      PATH_SEPARATOR = /[\/:;]/
      
      def initialize
        @graph ||= Graph.new
      end
      
      def register(path, handler)
        @graph << Route.new(path, handler)
      end
      
      def match(path)
        @graph.match(path)
      end
      
      private      
      class Graph
        def initialize
          @tree = {}
        end
        
        def <<(route)
          leaf = @tree
          token = nil
          route.tokens.each do |token|
            leaf = (leaf[token] ||= {})
          end
          
          leaf[token] = route
        end
        
        def match(path)
          token = nil
          m = nil
          route = path.split(PATH_SEPARATOR).inject(@tree) do |m,token|
            m[token]
          end
          
          if route
            route[token].to_proc
          else
            nil
          end
        end
        
        class Node
          def initialize(token, value)
            @token, @value = token, value
          end
          attr_reader :token, :value
        end
      end
    end
  end
end