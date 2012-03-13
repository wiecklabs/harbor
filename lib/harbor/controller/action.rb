module Harbor
  class Controller
    class Action
      def initialize(controller, name)
        @controller = controller
        @name       = name.to_sym
        @parameters = controller.instance_method(@name).parameters
      end

      attr_reader :controller, :name

      def call(request, response)
        args = build_args!(request, response)
        # TODO: Shouldn't we use Harbor::Container so that we can make use of dependency injection?
        controller.new(request, response).send(@name, *args)
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
            throw :abort_request
          end
        end
      end
    end
  end
end
