require "rubygems"

gem "erubis"
require "erubis"

require Pathname(__FILE__).dirname + "view_context"
require Pathname(__FILE__).dirname + "layouts"

module Harbor
  class View

    class LayoutNotFoundError < StandardError
      def initialize(name)
        super("Layout #{name.inspect} not found")
      end
    end

    def self.path
      @path ||= []
    end

    def self.layouts
      @layouts ||= Harbor::Layouts.new
    end

    def self.plugins
      @plugins ||= Hash.new { |h, k| h[k] = [] }
    end

    def self.plugin(name, plugin)

      case plugin
      when String
        plugin = Harbor::Plugin::String.new(plugin)
      when Class
        raise ArgumentError.new("#{plugin} must be a Plugin") unless Plugin > plugin
      else
        raise ArgumentError.new("#{plugin} must include Harbor::AccessorInjector") unless AccessorInjector > plugin
      end

      plugins[name] << plugin
    end

    @cache_templates = false
    def self.cache_templates?
      @cache_templates
    end

    def self.cache_templates!
      @cache_templates = true
    end

    def self.exists?(filename)
      self.path.detect { |dir| ::File.file?(dir + filename) }
    end

    attr_accessor :content_type, :context, :extension

    def initialize(view, context = {})
      @content_type = "text/html"
      @extension = ".html.erb"
      @view = view
      @context = context.is_a?(ViewContext) ? context : ViewContext.new(self, context)
    end

    def supports_layouts?
      true
    end
    
    def content
      @content ||= _erubis_render(@view, @context)
    end

    def to_s(layout = nil)
      layout = self.class.layouts.match(@view) if layout == :search

      layout ? View.new(layout, @context.merge(:content => content)).to_s : content
    end

    private

    def _erubis_render(filename, context)

      filename += self.extension if ::File.extname(filename) == ""

      path = self.class.exists?(filename)
      raise "Could not find '#{filename}' in #{self.class.path.inspect}" unless path

      full_path = path + filename

      if self.class.cache_templates?
        (self.class.__templates[path + filename] ||= Erubis::FastEruby.new(::File.read(full_path), :filename => full_path)).evaluate(context)
      else
        Erubis::FastEruby.new(::File.read(full_path), :filename => full_path).evaluate(context)
      end
    end

    def self.__templates
      @__templates ||= {}
    end
  end

end