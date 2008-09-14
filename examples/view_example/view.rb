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

  # This just maps a file name to a symbol for later use.
  def register(name, file)
    @partials[name] = file
  end

  # Render is the kicker method.
  def render(file)
    partials.each do |key, partial|
      path = self.path.detect { |dir| File.exists?(dir + partial) }
      next unless path
      path = path + partial

      # We go ahead and render the partial that was registered
      # and put its value back into the partials hash
      partials[key] = _render_erubis(path)
    end
    path = self.path.detect { |dir| File.exists?(dir + file) }

    # Now we render the main file
    _render_erubis(path + file)
  end

  # This method will retrieve the content of a named partial.
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