class Harbor::Cache

  class Item

    attr_reader :key, :ttl, :expires_at, :cached_at, :content, :maximum_age, :ultimate_expiration_time

    def initialize(key, ttl, maximum_age, string_or_io, cached_at, expires_at = nil)
      raise ArgumentError.new("Harbor::Cache::Item#initialize expects a String value for 'key', got #{key}") unless key.is_a?(String)
      raise ArgumentError.new("Harbor::Cache::Item#initialize expects a Fixnum value greater than 0 for 'ttl', got #{ttl}") unless ttl.is_a?(Fixnum) && ttl > 0
      raise ArgumentError.new("Harbor::Cache::Item#initialize expects nil, or a Fixnum value greater than 0 for 'maximum_age', got #{maximum_age}") unless maximum_age.nil? || (maximum_age.is_a?(Fixnum) && maximum_age > 0)
      raise ArgumentError.new("Harbor::Cache::Item#initialize expects a Time value for 'cached_at', got #{cached_at}") unless cached_at.is_a?(Time)
      raise ArgumentError.new("Harbor::Cache::Item#initialize expects a maximum_age greater than the ttl, got ttl: #{ttl}, maximum_age: #{maximum_age}") if maximum_age && ttl && (maximum_age <= ttl)

      @key = key
      @ttl = ttl
      @maximum_age = maximum_age
      @cached_at = cached_at
      @expires_at = expires_at || (cached_at + ttl)
      @ultimate_expiration_time = (maximum_age ? cached_at + maximum_age : nil)

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

    def fresh?
      Time.now < expires_at
    end

    def expired?
      Time.now >= expires_at
    end

    def bump
      if @ultimate_expiration_time
        @expires_at = [Time.now + ttl, @ultimate_expiration_time].min
      end
    end

  end

end