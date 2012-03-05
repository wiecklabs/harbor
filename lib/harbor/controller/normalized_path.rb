module Harbor
  class Controller
    class NormalizedPath

      def initialize(controller, path)
        @controller = controller
        @path = path
      end

      def split(splitter)
        to_s.split(splitter)
      end

      def to_s
        @normalized_path ||= begin
          if @path[0] == ?/
            @path[1..-1]
          else
            parts = [ ]
            klass = Kernel
            @controller.name.split("::").each do |part|
              klass = klass.const_get(part)
              if !(klass < Harbor::Application) && part != "Controllers"
                parts << part.underscore
              end
            end
            (parts << @path).join("/")
          end
        end
      end
    end
  end
end
