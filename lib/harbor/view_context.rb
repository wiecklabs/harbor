class Harbor
  class ViewContext
    include Enumerable
    require Pathname(__FILE__).dirname + "view_context/helpers"

    include Helpers::Form
    include Helpers::Text
    include Helpers::Html
    include Helpers::Url
    include Helpers::Cache
    include Helpers::Assets

    attr_accessor :view, :keys

    def initialize(view, variables)
      @view = view
      @keys = Set.new

      merge(variables)
    end

    def render(partial, variables = nil)
      context = to_hash

      result = View.new(partial, merge(variables)).to_s

      replace(context)

      result
    end

    def plugin(name, variables = {})
      if (plugin_list = Harbor::View::plugins(name)).any?
        plugin_list.map do |plugin|
          Plugin::prepare(plugin, self, variables)
        end
      else
        []
      end
    end

    def locale
      @locale ||= Harbor::Locale.default
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

    def [](key)
      instance_variable_get("@#{key}")
    end

    def []=(key, value)
      @keys << key
      instance_variable_set("@#{key}", value)
    end

    def merge(variables)
      variables.each do |key, value|
        self[key] = value
      end if variables

      self
    end

    def each
      keys.each { |key| yield(key, self[key]) }
    end

    def clear
      keys.each { |key| remove_instance_variable("@#{key}") }
      keys.clear

      self
    end

    def replace(variables)
      clear
      merge(variables)
    end

    def to_hash
      hash = {}
      keys.each { |key| hash[key] = self[key] }
      hash
    end

    private

    def request
      @request
    end

    def response
      @response
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
      yield(_erb_buffer(block.binding))
    end

  end
end
