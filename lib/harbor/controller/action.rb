class Harbor
  class Controller
    class Action
      def initialize(controller, name)
        @controller = controller
        @name       = name.to_sym
        @parameters = controller.instance_method(@name).parameters

        @controller_name = controller.name
        config.set(@controller_name, controller)
      end

      attr_reader :controller, :name

      def call(request, response)
        args = build_args!(request, response)
        controller = config.get(@controller_name, "request" => request, "response" => response)

        controller.filter! :before
        controller.send(@name, *args)
        controller.filter! :after
      end

      def inspect
        "#<Harbor::Controller::Action:<#{@controller}, #{@name}>>"
      end

      def to_s
        "Action<#{@controller}, #{@name}>"
      end

      private

      def build_args!(request, response)
        @parameters.each_with_object([]) do |param, args|
          type, name = param
          value = request.params[name.to_s]
          if value
            args << value
          elsif type == :req
            response.status = 400
            throw :halt
          end
        end
      end
    end
  end
end
