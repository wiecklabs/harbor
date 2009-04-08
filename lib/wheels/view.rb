require "rubygems"
require "erubis"
require Pathname(__FILE__).dirname + "view_context"

module Wheels
  class View

    def self.path
      @path ||= []
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

    def to_s(layout = nil)
      content = _erubis_render(@view, @context)
      layout ? View.new(layout, @context.merge(:content => content)).to_s : content
    end

    private

    def _erubis_render(filename, context)

      filename += self.extension if ::File.extname(filename) == ""

      path = self.class.exists?(filename)
      raise "Could not find '#{filename}' in #{self.class.path.inspect}" unless path

      if self.class.cache_templates?
        (self.class.__templates[path + filename] ||= Erubis::FastEruby.new(::File.read(path + filename))).evaluate(context)
      else
        Erubis::FastEruby.new(::File.read(path + filename)).evaluate(context)
      end
    end

    def self.__templates
      @__templates ||= {}
    end
  end
end