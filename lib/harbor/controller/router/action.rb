module Harbor
  class Controller
    class Router
      class Action
        def initialize(controller, name)
          @controller = controller
          @name = name.to_sym
        end
  
        attr_reader :controller, :name
  
        def call(request, response)
          controller.new(request, response).send(@name)
        end
        
        def inspect
          "#<Harbor::Controller::Router::Action:<#{@controller}, #{@name}>>"
        end
        
        def to_s
          "Action<#{@controller}, #{@name}>"
        end
      end
    end
  end
end