require 'thread'

module Harbor

  class Cache

    class Item

      attr_reader :key, :ttl, :expires_at, :maximum_age

      # This setter/getter may be overwritten in subclasses of CacheItem to provide custom storage
      attr_accessor :content

      def initialize(cache, key, ttl, maximum_age, cached_at = Time.now)
        raise ArgumentError.new("Harbor::Cache::Item#initialize expects a String value for 'key', got #{key}") unless key.is_a?(String)
        raise ArgumentError.new("Harbor::Cache::Item#initialize expects a Fixnum value greater than 0 for 'ttl', got #{ttl}") unless ttl.is_a?(Fixnum) && ttl > 0
        raise ArgumentError.new("Harbor::Cache::Item#initialize expects nil, or a Fixnum value greater than 0 for 'maximum_age', got #{maximum_age}") unless maximum_age.nil? || (maximum_age.is_a?(Fixnum) && maximum_age > 0)
        raise ArgumentError.new("Harbor::Cache::Item#initialize expects a Time value for 'cached_at', got #{cached_at}") unless cached_at.is_a?(Time)
        raise ArgumentError.new("Harbor::Cache::Item#initialize expects a maximum_age greater than the ttl, got ttl: #{ttl}, maximum_age: #{maximum_age}") if maximum_age && ttl && (maximum_age <= ttl)

        @cache, @ttl = cache, ttl
        @expires_at = (cached_at + ttl)
        @maximum_age = (maximum_age ? cached_at + maximum_age : nil)
      end

      def fresh?
        Time.now < expires_at
      end

      def expired?
        Time.now >= expires_at
      end

      def bump
        if maximum_age
          @expires_at = [Time.now + ttl, maximum_age].min
        end
      end

      def destroy_content
        # Nothing to do here since by default, CacheItem is held purely in memory
      end

    end

    class Memory

      def initialize
        @cache = {}
        @semaphore = Mutex.new
      end

      def put(key, content, ttl, maximum_age = nil)
        raise ArgumentError.new("Harbor::Cache::Memory#put expects a String value for 'key', got #{key}") unless key.is_a?(String)
        raise ArgumentError.new("Harbor::Cache::Memory#put expects a Fixnum value greater than 0 for 'ttl', got #{ttl}") unless ttl.is_a?(Fixnum) && ttl > 0
        raise ArgumentError.new("Harbor::Cache::Memory#put expects nil, or a Fixnum value greater than 0 for 'maximum_age', got #{maximum_age}") unless maximum_age.nil? || (maximum_age.is_a?(Fixnum) && maximum_age > 0)
        raise ArgumentError.new("Harbor::Cache::Memory#put expects a maximum_age greater than the ttl, got ttl: #{ttl}, maximum_age: #{maximum_age}") if maximum_age && ttl && (maximum_age <= ttl)

        @semaphore.synchronize do
          # Prevent multiple writes of similar content to the cache
          return true if @cache[key] && @cache[key].fresh? && @cache[key].content.hash == content.hash
          @cache[key] = Harbor::Cache::Item.new(self, key, ttl, maximum_age, Time.now)
          @cache[key].content = content
        end
      end

      def get(key)
        if item = @cache[key]
          if item.fresh?
            @semaphore.synchronize { item.bump }
            item
          else
            delete(key)

            nil
          end
        else
          nil
        end
      end

      def delete(key)
        @semaphore.synchronize do
          if item = @cache[key]
            item.destroy_content
            @cache.delete(key)
          end
        end
      end

    end

  end

end