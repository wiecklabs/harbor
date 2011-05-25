module Harbor
  class Layouts

    include Enumerable

    def initialize
      @map = []
      @default = nil
      @default_initialized = false
    end

    def map(fragment, layout)
      fragment = fragment.squeeze("*").squeeze("/").sub(%r{/$}, "").gsub("*", ".*")
      specificity = fragment_specificity(fragment)

      regexp = Regexp.new("^#{fragment}")

      if previous = @map.assoc(regexp)
        @map[@map.index(previous)] = [regexp, layout, specificity]
      else
        @map << [regexp, layout, specificity]
      end

      sort!
      @map
    end

    def default(layout)
      @default_initialized = true
      @default = layout
    end

    def each
      @map.each { |item| yield item }
    end

    def sort!
      @map.sort! do |a, b|
        b[2] <=> a[2]
      end
    end

    def clear
      @default = nil
      @default_initialized = false
      @map.clear
    end

    def match(path)
      @map.each do |fragment, layout|
        return layout if fragment === path
      end

      return __default
    end

    private
    def __default
      if @default_initialized
        @default
      else
        @default_initialized = true
        @default ||= View.exists?("layouts/application") ? "layouts/application" : nil
      end
    end
    
    def fragment_specificity(fragment)
      fragment.count("/") - fragment.count("*")
    end

  end
end