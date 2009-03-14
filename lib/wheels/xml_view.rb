require "builder"

module Wheels
  class XMLViewContext < ViewContext

    def render(partial, variables=nil)
      push_variables(variables)
      result = XMLView.new(partial, self).to_s
      pop_variables
      result
    end

    def xml
      @view.xml
    end

  end

  class XMLView < View

    attr_accessor :xml, :output

    def initialize(view, context = {})
      super
      @content_type = "text/xml"
      @extension = ".rxml"
      @output = ""
      @xml = Builder::XmlMarkup.new(:indent => 2, :target => output)
      @context = context.is_a?(ViewContext) ? context : XMLViewContext.new(self, context)
    end

    def to_s(layout = nil)
      warn "Layouts are not supported for XMLView objects." if layout

      filename = @view
      filename += self.extension if File.extname(filename) == ""

      path = View::path.detect { |dir| File.exists?(dir + filename) }
      raise "Could not find '#{@view}' in #{View::path.inspect}" if path.nil?

      eval_code = File.read(path + filename)
      XMLViewContext.new(self, @context).instance_eval(eval_code, __FILE__, __LINE__)

      @output
    end
  end
end