class Harbor::Cache

  class Item

    attr_reader :key, :ttl, :cached_at, :content

    def initialize(key, ttl, string_or_io, cached_at)
      raise ArgumentError.new("Harbor::Cache::Item#initialize expects a String value for 'key', got #{key}") unless key.is_a?(String)
      raise ArgumentError.new("Harbor::Cache::Item#initialize expects a Fixnum value greater than 0 for 'ttl', got #{ttl}") unless ttl.is_a?(Fixnum) && ttl > 0
      raise ArgumentError.new("Harbor::Cache::Item#initialize expects a Time value for 'cached_at', got #{cached_at}") unless cached_at.is_a?(Time)

      @key = key
      @ttl = ttl
      @cached_at = cached_at

      if string_or_io.respond_to?(:read)
        @io = string_or_io
      else
        @content_fetched = true
        @content = string_or_io
      end
    end

    def content
      read_io unless @content_fetched
      @content
    end

    def read_io
      @content_fetched = true
      @content = begin
        @io.read
      rescue
        nil
      end
    end

  end

end
