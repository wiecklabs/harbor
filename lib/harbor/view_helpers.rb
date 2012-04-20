class Harbor
  class ViewHelpers
    attr_reader :paths

    def initialize
      @paths = []
    end

    def register_all!
      Dir["{#{@paths.join(",")}}"].each do |file|
        require ::File.expand_path file
      end

      Harbor::registered_applications.each do |app|
        next unless app.const_defined? :Helpers
        app::Helpers::constants.each do |const|
          helper = app::Helpers::const_get(const)
          register(helper) if helper.is_a?(Module) && ! helper.is_a?(Class)
        end
      end
    end

    def register(helper)
      ViewContext.instance_eval { include helper }
    end
  end
end
