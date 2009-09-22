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
    
  end
end