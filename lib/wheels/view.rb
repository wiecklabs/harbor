require "rubygems"
require "erubis"

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

end

class View
  def self.path
    @path ||= []
  end

  attr_accessor :content_type, :context

  def initialize(view, context = nil)
    @content_type = "text/html"
    @view = view
    @context = context
  end

  def to_s(layout = nil)
    content = _erubis_render(@view, @context)
    layout ? View.new(layout, @context.merge(:content => content)) : content
  end

  private

  def _erubis_render(filename, context = nil)
    path = self.class.path.detect { |dir| File.exists?(dir + filename) }
    raise "Could not find '#{filename}' in #{self.class.path.inspect}" if path.nil?

    context = ViewContext.new(self, context) unless context.is_a?(ViewContext)
    Erubis::FastEruby.new(File.read(path + filename)).evaluate(context)
  end

end