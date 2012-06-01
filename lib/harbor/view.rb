begin
  require "erubis"
rescue LoadError; end

require "tilt"

require_relative "view_helpers"
require_relative "view_context"
require_relative "layouts"
require_relative "plugin_list"
require_relative "template_lookup"

class Harbor
  class View

    class LayoutNotFoundError < StandardError
      def initialize(name)
        super("Layout #{name.inspect} not found")
      end
    end

    def self.paths
      lookup.paths
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
      lookup.exists?(filename)
    end

    attr_accessor :content_type, :context

    def initialize(view, context = {})
      @context = context.is_a?(ViewContext) ? context : ViewContext.new(self, context)
      @filename = view
    end

    def content
      @content ||= render(@context)
    end

    def to_s(layout = nil)
      # TODO: Should support layout based on content type / format as well
      layout = self.class.layouts.match(@filename) if layout == :search
      layout ? View.new(layout, @context.merge(:content => content)).to_s : content
    end

    private

    def render(context)
      format, full_path = self.class.lookup.find(@filename, @context[:format])
      # Sets the format so that we render partials properly
      @context[:format] = format unless @context[:format]

      template = if self.class.cache_templates?
        self.class.tilt_cache.fetch(full_path) { Tilt.new(full_path.to_s) }
      else
        Tilt.new(full_path.to_s)
      end
      template.render(context)
    end

    def self.tilt_cache
      @tilt_cache ||= Tilt::Cache.new
    end

    def self.lookup
      @lookup ||= TemplateLookup.new
    end
  end
end
