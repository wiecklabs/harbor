require "thread"
require_relative "cache/item"

module Harbor

  class Cache

    def self.redis(connection, name = nil)
      require "harbor/cache/redis"
      self.new(Harbor::Cache::Redis.new(connection, name))
    end

    class PutArgumentError < ArgumentError; end

    attr_accessor :logger

    def initialize(store)
      raise ArgumentError.new("Harbor::Cache.new expects a non-null 'store' parameter") unless store
      logger.debug "INIT: #{store.inspect}" if logger

      @store = store
      @semaphore = Mutex.new
    end

    def put(key, content, ttl, maximum_age = nil)
      raise PutArgumentError.new("Harbor::Cache::Memory#put expects a String value for 'key', got #{key}") unless key.is_a?(String)
      raise PutArgumentError.new("Harbor::Cache::Memory#put expects a Fixnum value greater than 0 for 'ttl', got #{ttl}") unless ttl.is_a?(Fixnum) && ttl > 0
      raise PutArgumentError.new("Harbor::Cache::Memory#put expects nil, or a Fixnum value greater than 0 for 'maximum_age', got #{maximum_age}") unless maximum_age.nil? || (maximum_age.is_a?(Fixnum) && maximum_age > 0)
      raise PutArgumentError.new("Harbor::Cache::Memory#put expects a maximum_age greater than the ttl, got ttl: #{ttl}, maximum_age: #{maximum_age}") if maximum_age && ttl && (maximum_age <= ttl)

      @semaphore.synchronize do
        # Prevent multiple writes of similar content to the cache
        return true if (cached_item = @store.get(key)) && cached_item.fresh? && cached_item.content.hash == content.hash

        logger.debug "PUT: #{key}  (ttl:#{ttl.inspect} maximum_age:#{maximum_age.inspect})" if logger
        @store.put(key, ttl, maximum_age, content, Time.now)
      end
    rescue
      log("Harbor::Cache#put unable to store cached content.", $!)

      raise if $!.is_a?(PutArgumentError)
    ensure
      content
    end

    def get(key)
      if item = @store.get(key)
        logger.debug "HIT: #{key.inspect}" if logger
        if item.fresh?
          logger.debug "BUMP: #{key.inspect}" if logger
          @semaphore.synchronize do
            @store.bump(key)
          end

          item
        else
          delete(key)

          item = nil
        end
      else
        item = nil
      end
    rescue
      log("Harbor::Cache#get unable to retrieve cached content.", $!)
    ensure
      defined?(item) ? item : nil
    end

    def delete(key)
      logger.debug "DELETE: #{key.inspect}" if logger
      @semaphore.synchronize do
        @store.delete(key)
      end
    rescue
      log("Harbor::Cache#put unable to delete cached content.", $!)
    ensure
      nil
    end

    def delete_matching(key)
      logger.debug "DELETE MATCHING: #{key.inspect}" if logger
      @semaphore.synchronize do
        @store.delete_matching(key)
      end
    rescue
      log("Harbor::Cache#put unable to delete cached content.", $!)
    ensure
      nil
    end

    private

    def log(message, error)
      if @logger
        @logger.fatal("#{message} #{$!}\n#{$!.message}\nBacktrace:\n#{$!.backtrace.join("\n")}")
      end
    end

  end

end

Dir[Pathname(__FILE__).dirname + "cache" + "*.rb"].each do |file|
  require Pathname(file).dirname + File.basename(file)
end
