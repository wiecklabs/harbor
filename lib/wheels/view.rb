require "rubygems"
require "erubis"

class ViewContext < Erubis::Context

  attr_accessor :view

  def initialize(view, variables)
    @view = view
    @variables = variables
  end

  def puts(partial)
    view.send(:_erubis_render, view.partials.delete(partial), self)
  end

end

class View
  def self.path
    @path ||= []
  end

  attr_accessor :content_type

  def initialize(view, partials = {})
    @content_type = "text/html"
    @view = view
    @partials = partials
    @cache = ""
  end

  def []=(name, file)
    @partials[name] = file
  end

  def render(context = nil)
    @cache = _erubis_render(@view, context)
    self
  end

  def to_s
    @cache || _erubis_render(@view)
  end

  private

  def _erubis_render(filename, context = nil)
    path = self.class.path.detect { |dir| File.exists?(dir + filename) }
    raise "Could not find '#{filename}' in #{self.class.path.inspect}" if path.nil?

    context = ViewContext.new(self, context) unless context.is_a?(ViewContext)
    Erubis::FastEruby.new(File.read(path + filename)).evaluate(context)
  end

end