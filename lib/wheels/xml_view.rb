require "builder"

class XMLView < View

  def content_type() "text/xml" end

  def to_s(layout = nil)
    warn "Layouts are not supported for XMLView objects." if layout

    path = View::path.detect { |dir| File.exists?(dir + @view) }
    raise "Could not find '#{@view}' in #{View::path.inspect}" if path.nil?

    output = ""
    xml = Builder::XmlMarkup.new(:indent => 2, :target => output)

    eval_code = File.read(path + @view)
    instance_eval(eval_code, __FILE__, __LINE__)

    output
  end
end