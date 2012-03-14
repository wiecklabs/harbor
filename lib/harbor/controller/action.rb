module Harbor
  class Controller
    class Action
      def initialize(controller, name)
        @controller = controller
        @name = name.to_sym
        
        @controller_name = controller.name
        config.set(@controller_name, controller)
      end

      attr_reader :controller, :name

      def call(request, response)
        config.get(@controller_name, "request" => request, "response" => response).send(@name)
      end

      def inspect
        "#<Harbor::Controller::Action:<#{@controller}, #{@name}>>"
      end

      def to_s
        "Action<#{@controller}, #{@name}>"
      end
    end
  end
end