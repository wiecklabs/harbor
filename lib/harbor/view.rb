require "erubis"
require "tilt"

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

    def self.engines
      @engines ||= ['erb']
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
      return false if self.path.none?

      extension = ::File.extname(filename)
      file_pattern = filename
      file_pattern << ".html.{#{self.engines.join(',')}}" if extension.empty?
      pattern = "{#{self.path.join(',')}}/**/#{file_pattern}"
      Dir[pattern].first
    end

    attr_accessor :content_type, :context, :extension, :path

    def initialize(view, context = {})
      @content_type = "text/html"
      @context = context.is_a?(ViewContext) ? context : ViewContext.new(self, context)
      @filename = view
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
      full_path ||= self.class.exists?(@filename)
      raise "Could not find '#{@filename}' in #{self.class.path}" unless full_path

      # TODO: This could probably be based on the current environment
      template = if self.class.cache_templates?
        self.class.tilt_cache.fetch(full_path) { Tilt.new(full_path) }
      else
        Tilt.new(full_path.to_s, :engine_class => Erubis::FastEruby)
      end
      template.render(context)
    end

    def self.tilt_cache
      @tilt_cache ||= Tilt::Cache.new
    end
  end

end
