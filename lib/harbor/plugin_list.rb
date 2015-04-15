module Harbor
  class PluginList

    include Enumerable

    def initialize
      @plugins = []
    end

    def each
      @plugins.each do |plugin|
        yield plugin
      end
    end

    def size
      @plugins.size
    end

    def clear
      @plugins.clear
    end

    def <<(plugin)
      case plugin
      when String
        plugin = Harbor::Plugin::String.new(plugin)
      when Class
        raise ArgumentError.new("#{plugin} must be a Plugin") unless Plugin > plugin
      else
        raise ArgumentError.new("#{plugin} must include Harbor::AccessorInjector") unless AccessorInjector > plugin
      end

      @plugins << plugin
    end

    def render(view_context, variables = {})
      Renderer.new(@plugins, view_context, variables)
    end

  end

  class PluginList::Renderer

    include Enumerable

    def initialize(plugins, view_context, variables)
      @rendered_plugins = plugins.map { |plugin| Plugin::prepare(plugin, view_context, variables) }
    end

    def each
      @rendered_plugins.each do |rendered_plugin|
        yield rendered_plugin
      end
    end

    def to_s
      @rendered_plugins.join
    end

  end
end