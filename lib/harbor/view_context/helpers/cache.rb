##
# Set Harbor::View.fragment_cache_store equal to a supported Cache Store for use
# in the ViewContext#cache helper.
##
class Harbor::View

  class << self

    def fragment_cache_store=(value)
      @fragment_cache_store = value
    end

    def fragment_cache_store
      @fragment_cache_store
    end

  end

end

##
# Cache helper that provides fragment-caching
##
module Harbor::ViewContext::Helpers::Cache

  ##
  #   Caches the result of a block using the given TTL and maximum_age values.
  #   If no ttl is given, a default of 30 minutes is used.  If no maximum_age value is given
  #   the item will expire after Time.now + ttl.  If a maximum_age is specified, "get" requests
  #   to the cache for a given key will push the expiration time up for the item by the TTL, until
  #   Time.now + TTL is equal to or greater than the cache-insertion-time + maximum_age.
  ##
  def cache(key, ttl = 30 * 60, max_age = nil, &generator)
    store = @cache_store || Harbor::View.fragment_cache_store

    if store.nil?
      raise ArgumentError.new("Cache Store Not Defined.  Please set Harbor::ViewContext.fragment_cache_store to your desired cache store.")
    end

    content = if item = store.get(key)
      item.content
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