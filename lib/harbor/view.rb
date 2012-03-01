require "erubis"

require_relative "view_context"
require_relative "layouts"
require_relative "plugin_list"

module Harbor
  class View

    class LayoutNotFoundError < StandardError
      def initialize(name)
        super("Layout #{name.inspect} not found")
      end
    end

    def self.path
      @path ||= if ::File.directory?("lib/views")
        [ Pathname("lib/views") ]
      else
        []
      end
    end

    def self.layouts
      @layouts ||= Harbor::Layouts.new
    end

    def self.plugins(key)
      @plugins ||= Hash.new { |h, k| h[k] = PluginList.new }

      @plugins[key.to_s.gsub(/^\/+/, '')]
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

    attr_accessor :content_type, :context, :extension, :path

    def initialize(view, context = {})
      @content_type = "text/html"
      @extension = ".html.erb"
      @context = context.is_a?(ViewContext) ? context : ViewContext.new(self, context)
      @filename = ::File.extname(view) == "" ? (view + @extension) : view
    end

    def supports_layouts?
      true
    end

    def content
      @content ||= _erubis_render(@context)
    end

    def to_s(layout = nil)
      layout = self.class.layouts.match(@filename) if layout == :search

      layout ? View.new(layout, @context.merge(:content => content)).to_s : content
    end

    private

    def _erubis_render(context)
      @path ||= self.class.exists?(@filename)
      raise "Could not find '#{@filename}' in #{self.class.path.inspect}" unless @path

      full_path = @path + @filename

      if self.class.cache_templates?
        (self.class.__templates[full_path] ||= Erubis::FastEruby.new(::File.read(full_path), :filename => full_path)).evaluate(context)
      else
        Erubis::FastEruby.new(::File.read(full_path), :filename => full_path.to_s).evaluate(context)
      end
    end

    def self.__templates
      @__templates ||= {}
    end
  end

end
