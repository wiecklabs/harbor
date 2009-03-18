module Wheels
  class ViewContext < Erubis::Context
    require Pathname(__FILE__).dirname + "view_context/helpers"

    include Helpers::Form

    attr_accessor :view

    def initialize(view, variables)
      @view = view
      push_variables(variables)
      super(variables)
    end

    def merge(variables)
      push_variables(variables)
      self
    end

    def render(partial, variables=nil)
      push_variables(variables)
      result = View.new(partial, self).to_s
      pop_variables
      result
    end

    def q(value)
      Rack::Utils::escape(value)
    end

    def h(value)
      Rack::Utils::escape_html(value)
    end

    def inspect
      "Wheels::ViewContext <#{variable_frames.inspect}>"
    end

    def capture(*args, &block)
      # get the buffer from the block's binding
      buffer = _erb_buffer( block.binding ) rescue nil

      # If there is no buffer, just call the block and get the contents
      if buffer.nil?
        block.call(*args)
      # If there is a buffer, execute the block, then extract its contents
      else
        pos = buffer.length

        block.call(*args)

        # extract the block
        data = buffer[pos..-1]

        # replace it in the original with empty string
        buffer[pos..-1] = ''

        data
      end
    end

    private

    def push_variables(variables)
      if variables.is_a?(Hash)
        named_variables = {}
        variables.each do |name, value|
          if name.to_s[0,1] == "@"
            named_variables[name] = value
          else
            named_variables["@#{name}"] = value
          end
        end

        variable_frames.push(named_variables)

        named_variables.each do |name, value|
          instance_variable_set(name, value)
        end
      else
        variable_frames.push({})
      end
    end

    def pop_variables
      if frame = variable_frames.pop
        frame.each do |name, value|
          instance_variable_set(name, nil)
        end
      end

      if frame = variable_frames.last
        frame.each do |name, value|
          instance_variable_set(name, value)
        end
      end
    end

    def variable_frames
      @variable_frames ||= []
    end

    def request
      @request
    end

    def _erb_buffer( the_binding ) # :nodoc:
      eval( "_buf", the_binding, __FILE__, __LINE__)
    end

    ##
    # Useful when you need to output content to the buffer.
    # 
    #   def wrap_with_p_tag(&block)
    #     with_buffer(block) do |buffer|
    #       buffer << "<p>" << capture(&block) << "</p>"
    #     end
    #   end
    ##
    def with_buffer(block)
      yield(StringIO.new(_erb_buffer(block.binding)))
    end

  end
end