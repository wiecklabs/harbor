require "rubygems"

gem "erubis"
require "erubis"

require Pathname(__FILE__).dirname + "view_context"
require Pathname(__FILE__).dirname + "layouts"
require Pathname(__FILE__).dirname + "plugin_list"

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

    def self.exists?(filename, theme = nil)
      if theme
        self.path.map { |dir| dir + "themes" + theme }.detect { |path| ::File.file?(path + filename) }
      end || self.path.detect { |dir| ::File.file?(dir + filename) }
    end

    attr_accessor :content_type, :context, :extension, :path

    def initialize(view, context = {})
      @content_type = "text/html"
      @extension = ::File.extname(view).downcase
      @context = context.is_a?(ViewContext) ? context : ViewContext.new(self, context)
      @filename = ::File.extname(view) == "" ? (view + ".html.erb") : view
    end

    def supports_layouts?
      true
    end

    def content
      @content ||= render(@context)
    end

    def to_s(layout = nil)
      layout = self.class.layouts.match(@filename) if layout == :search

      layout ? View.new(layout, @context.merge(:content => content)).to_s : content
    end

    private

    def render(context)
      @path ||= self.class.exists?(@filename, context.theme)
      raise "Could not find '#{@filename}' in #{self.class.path.inspect}" unless @path

      full_path = @path + @filename

      if @extension == ".html"
        ::File.read(full_path)
      else
        _erubis_render(context, full_path)
      end
    end

    def _erubis_render(context, full_path)
      @path ||= self.class.exists?(@filename, context.theme)
      raise "Could not find '#{@filename}' in #{self.class.path.inspect}" unless @path

      if self.class.cache_templates?
        (self.class.__templates[full_path] ||= Erubis::FastEruby.new(::File.read(full_path), :filename => full_path)).evaluate(context)
      else
        Erubis::FastEruby.new(::File.read(full_path.to_s), :filename => full_path.to_s).evaluate(context)
      end
    end

    def self.__templates
      @__templates ||= {}
    end
  end
end
