require "logging"
require "redis_directory"

if RUBY_PLATFORM =~ /java/
  require "java"
else
  require "uuid"
end

class Harbor::Cache::Redis

  TRACKER_KEY_NAME = "cache-keys"

  def initialize(connection, name = nil, logger = nil)
    if connection.is_a?(Redis) || connection.is_a?(Redis::Distributed)
      @redis = connection
    else
      @redis = Redis::Directory.new(connection).get("cache", name)
    end

    @logger = logger || Logging::Logger[self]
  end

  def get(key)
    if (value = @redis.get(key))
      @logger.debug "REDIS-CACHE:HIT #{key.inspect}"
      load_item(key, value)
    else
      @redis.srem(TRACKER_KEY_NAME, key)
      @logger.debug "REDIS-CACHE:MISS #{key.inspect}"
      nil
    end
  end

  alias [] get

  def put(key, ttl, maximum_age, content, cached_at)
    item = Harbor::Cache::Item.new(key, ttl, content, cached_at)
    data = { "ttl" => item.ttl, "content" => item.content, "cached_at" => item.cached_at }
    @redis.setex(key, ttl, YAML::dump(data))
    @redis.sadd(TRACKER_KEY_NAME, key)

    @logger.debug("REDIS-CACHE: #{key.inspect} stored with ttl=#{ttl}")

    item
  end

  def delete(key)
    @redis.del(key)
    @redis.srem(TRACKER_KEY_NAME, key)

    @logger.debug("REDIS-CACHE: #{key} deleted")
  end

  def delete_matching(key_regex)
    if (matches = keys_matching(key_regex)).empty?
      nil
    else
      matches.each do |match|
        @redis.srem(TRACKER_KEY_NAME, match)
      end
      @redis.srem(TRACKER_KEY_NAME, *matches)
      @redis.del(*matches)

      @logger.debug("REDIS-CACHE: Deleted #{matches.size} keys matching #{key_regex}")
    end
  end

  def keys_matching(key_regex)
    @redis.smembers(TRACKER_KEY_NAME).select { |key| key =~ key_regex }
  end

  def load_item(key, data)
    value = YAML::load(data)
    Harbor::Cache::Item.new(key, value["ttl"], value["content"], value["cached_at"])
  end
end
