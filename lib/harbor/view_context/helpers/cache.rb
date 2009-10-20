##
# Set Harbor::View.cache equal to a supported Cache Store for use
# in the ViewContext#cache helper.
##
class Harbor::View

  class << self

    def cache=(value)
      if value && !value.is_a?(Harbor::Cache)
        raise ArgumentError.new("Harbor::View.cache must be nil or an instance of Harbor::Cache")
      end

      @__cache__ = value
    end

    def cache
      @__cache__
    end

  end

end

##
# Cache helper that provides fragment-caching
##
module Harbor::ViewContext::Helpers::Cache

  class CacheRenderError < StandardError
    def initialize(inner_error, content_item)
      @inner_error = inner_error
      @content_item = content_item
    end
    
    def to_s
      "#{@content_item.class.name}:#{@content_item.inspect}\n\t#{@inner_error.message}"
    end
    
    def inspect
      "<#CacheRenderError content_item=#{@content_item.class.name}:#{@content_item.inspect} inner_error=#{@inner_error.inspect} backtrace=#{@inner_error.backtrace.join("\n\t")}>"
    end
  end
  
  ##
  #   Caches the result of a block using the given TTL and maximum_age values.
  #   If no ttl is given, a default of 30 minutes is used.  If no maximum_age value is given
  #   the item will expire after Time.now + ttl.  If a maximum_age is specified, "get" requests
  #   to the cache for a given key will push the expiration time up for the item by the TTL, until
  #   Time.now + TTL is equal to or greater than the cache-insertion-time + maximum_age.
  ##
  def cache(key, ttl = 30 * 60, max_age = nil, &generator)
    store = @cache_store || Harbor::View.cache

    if store.nil?
      raise ArgumentError.new("Cache Store Not Defined.  Please set Harbor::View.cache to your desired cache store.")
    end

    content = if item = store.get(key)
      begin
        item.content
      rescue => e
        raise CacheRenderError.new(e, item)
      end
    else
      data = capture(&generator)
      store.put(key, data, ttl, max_age)

      data
    end

    with_buffer(generator) do |buffer|
      buffer << content
    end
  end

end