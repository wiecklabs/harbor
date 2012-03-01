require 'sequel'
require 'i18n'

module Harbor
  module Contrib
    module Translations
      class Translation < Sequel::Model
        
        def initialize(redis)
          @redis = redis
          @kvstore = I18n::Backend::KeyValue.new(redis)
          I18n.backend = I18n::Backend::Chain.new(@kvstore, I18n.backend)
        end
        
        def get(locale, key)
          return nil if !key || !locale

          if keys = @redis.smembers(scope)
            if keys
              if translation = keys[key]
                return translation[2]
              else
                return cache(key, locale, scope)
              end
            end
          else
            # The scope wasn't found in redis, so look at the database...
            return cache(key, locale, scope)
          end

          key
        end

        # Adds translation if it does not already exist
        def put(locale, key, value)
          if (!self.exists_in_redis?(locale, key))
            self.put!(locale, key, value)
          end
        end

        # Adds translation, regardless of existence
        def put!(locale, key, value)
          I18n.backend.store_translations(locale, {key => value}, :escape => false)
        end

        def exists_in_redis?(locale, key)
          puts "-=-=-=> #{@kvstore.translate(locale, key)}"
          @kvstore.translate(locale, key)
        end

        def exists_in_db?(locale, key)
          false
        end

        
        private
        def cache(locale, key)
          # Not found in redis...
          translations = all(:scope => scope)
          # Put 'em in redis...
          # return the actual entry
        end
        
      end
    end
  end
end
