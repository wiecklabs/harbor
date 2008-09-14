require "rubygems"
require "erubis"
require "pathname"

class View < Erubis::FastEruby
  attr_accessor :path, :partials, :context

  def initialize(path, context = nil)
    @path = [path]
    @partials = {}
    @context = context
  end

  def register(name, file)
    @partials[name] = file
  end

  def render(file)
    partials.each do |key, partial|
      path = self.path.detect { |dir| File.exists?(dir + partial) }
      next unless path
      path = path + partial
      partials[key] = _render_erubis(path)
    end
    path = self.path.detect { |dir| File.exists?(dir + file) }
    _render_erubis(path + file)
  end

  def get(handle)
    @partials.delete(handle)
  end

  private

  def _render_erubis(file)
    self.convert!(File.read(file))
    evaluate(context)
  end
end

require Pathname(__FILE__).dirname + "controllers/hello"

require "stringio"
response = StringIO.new("")
hello = Hello.new({}, response)
hello.world
puts response.string