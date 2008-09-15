require "rubygems"
require "erubis"
require "pathname"

class Erubis::Context
  attr_accessor :view
  def initialize(view, hash)
    @view = view
    super(hash) unless hash.nil?
  end
  def puts(partial)
    view.partials.delete(partial)
  end
end

class View < Erubis::FastEruby
  attr_accessor :path, :partials, :context

  def initialize(path)
    @path = [path]
    @partials = {}
  end

  # This just maps a file name to a symbol for later use.
  def register(name, file)
    @partials[name] = file
  end

  # Render is the kicker method.
  def render(file, context = nil)
    partials.each do |key, partial|
      path = self.path.detect { |dir| File.exists?(dir + partial) }
      next unless path
      path = path + partial

      # We go ahead and render the partial that was registered
      # and put its value back into the partials hash
      partials[key] = _render_erubis(path, context)
    end
    path = self.path.detect { |dir| File.exists?(dir + file) }

    # Now we render the main file
    _render_erubis(path + file, context)
  end

  private

  def _render_erubis(file, context)
    self.convert!(File.read(file))
    evaluate(Erubis::Context.new(self, context))
  end
end

require Pathname(__FILE__).dirname + "controllers/hello"

require "stringio"
response = StringIO.new("")
hello = Hello.new({}, response)
hello.world
puts response.string