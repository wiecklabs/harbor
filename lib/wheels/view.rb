require "rubygems"
require "erubis"

module Wheels
  class ViewContext < Erubis::Context

    attr_accessor :view

    def initialize(view, variables)
      @view = view
      @variables = variables
      super(variables)
    end

    def render(partial)
      View.new(partial, self)
    end

    def q(value)
      Rack::Utils::escape(value)
    end

    def h(value)
      Rack::Utils::escape_html(value)
    end
    
    private
    def request
      @request
    end

  end
  
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

    attr_accessor :content_type, :context, :extension

    def initialize(view, context = {})
      @content_type = "text/html"
      @extension = ".html.erb"
      @view = view
      @context = context
    end

    def to_s(layout = nil)
      content = _erubis_render(@view, @context)
      layout ? View.new(layout, @context.merge(:content => content)).to_s : content
    end

    private

    def _erubis_render(filename, context = {})

      filename += self.extension if File.extname(filename) == ""

      path = self.class.path.detect { |dir| File.exists?(dir + filename) }
      raise "Could not find '#{filename}' in #{self.class.path.inspect}" if path.nil?

      context = ViewContext.new(self, context) unless context.is_a?(ViewContext)
    
      if self.class.cache_templates?
        (self.class.__templates[path + filename] ||= Erubis::FastEruby.new(File.read(path + filename))).evaluate(context)
      else
        Erubis::FastEruby.new(File.read(path + filename)).evaluate(context)
      end
    end

    def self.__templates
      @__templates ||= {}
    end
  end
end