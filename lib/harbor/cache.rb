require "thread"
require Pathname(__FILE__).dirname + "logging"
require Pathname(__FILE__).dirname + "cache/item"

module Harbor

  class Cache

    def self.redis(connection, name = nil, logger = nil)
      require "harbor/cache/redis"
      self.new(Harbor::Cache::Redis.new(connection, name, logger), logger)
    end

    class PutArgumentError < ArgumentError; end

    def initialize(store, logger = nil)
      raise ArgumentError.new("Harbor::Cache.new expects a non-null 'store' parameter") unless store

      @logger = logger || Logging::Logger[self]
      @store = store
      @logger.debug "HC:INIT #{@store.inspect}"
    end

    def put(key, content, ttl)
      raise PutArgumentError.new("Harbor::Cache::Memory#put expects a String value for 'key', got #{key}") unless key.is_a?(String)
      raise PutArgumentError.new("Harbor::Cache::Memory#put expects a Fixnum value greater than 0 for 'ttl', got #{ttl}") unless ttl.is_a?(Fixnum) && ttl > 0

      @logger.debug "HC:PUT #{key.inspect} (ttl: #{ttl.inspect})"
      @store.put(key, ttl, nil, content, Time.now)
    rescue
      raise if $!.is_a?(PutArgumentError)
      log_fatal("Unable to store cached content.", $!)
    ensure
      content
    end

    def get(key)
      @logger.debug "HC:GET #{key.inspect}"
      @store.get(key)
    rescue
      log_fatal("Unable to retrieve cached content.", $!)
    end

    def delete(key)
      @logger.debug "HC:DELETE #{key.inspect}"
      @store.delete(key)
    rescue
      log_fatal("Unable to delete cached content.", $!)
    ensure
      nil
    end

    def delete_matching(key)
      @logger.debug "HC:DELETE MATCHING #{key.inspect}"
      @store.delete_matching(key)
    rescue
      log_fatal("Unable to delete cached content.", $!)
    ensure
      nil
    end

    private

    def log_fatal(message, error)
      @logger.fatal("HC:ERROR - #{message} #{error}\n#{error.message}\nBacktrace:\n#{error.backtrace.join("\n")}")
    end

  end

end

Dir[Pathname(__FILE__).dirname + "cache" + "*.rb"].each do |file|
  require Pathname(file).dirname + File.basename(file)
end
