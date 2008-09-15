require "rubygems"
require "erubis"
require "pathname"

class Erubis::Context
  attr_accessor :view
  def initialize(view, ivars)
    @view = view
    @ivars = ivars
    super(ivars) unless ivars.nil?
  end

  def puts(partial)
    view.render(view.partials.delete(partial), @ivars)
  end
end

class View < Erubis::FastEruby
  attr_accessor :path, :partials, :context

  def initialize(path)
    @path = [path]
    @partials = {}
  end

  # This just maps a file name to a symbol for later use.
  def []=(name, file)
    @partials[name] = file
  end

  # Render is the kicker method.
  def render(view, context = nil)
    path = self.path.detect { |dir| File.exists?(dir + view) }
    self.convert!(File.read(path + view))
    evaluate(Erubis::Context.new(self, context))
  end
end

require Pathname(__FILE__).dirname + "controllers/hello"

require "stringio"
response = StringIO.new("")
hello = Hello.new({}, response)
hello.world
puts response.string