require "builder"

class XMLViewContext < ViewContext

  def xml
    @view.xml
  end

end

class XMLView < View

  attr_accessor :xml, :output

  def initialize(view, context = {})
    super
    @output = ""
    @xml = Builder::XmlMarkup.new(:indent => 2, :target => output)
  end

  def content_type() "text/xml" end

  def to_s(layout = nil)
    warn "Layouts are not supported for XMLView objects." if layout

    path = View::path.detect { |dir| File.exists?(dir + @view) }
    raise "Could not find '#{@view}' in #{View::path.inspect}" if path.nil?

    eval_code = File.read(path + @view)
    XMLViewContext.new(self, @context).instance_eval(eval_code, __FILE__, __LINE__)

    @output
  end
end