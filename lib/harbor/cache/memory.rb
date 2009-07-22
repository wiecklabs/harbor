require Pathname(__FILE__).dirname.parent + "cache"

class Harbor::Cache::Memory

  def initialize
    @cache = {}
  end

  def put(key, ttl, maximum_age, content, cached_at)
    @cache[key]= Harbor::Cache::Item.new(key, ttl, maximum_age, content, cached_at)
  end

  def get(key)
    @cache[key]
  end

  def [](key)
    @cache[key]
  end

  def delete(key)
    @cache.delete(key)
  end

  def bump(key)
    if item = @cache[key]
      item.bump
    end
  end

end