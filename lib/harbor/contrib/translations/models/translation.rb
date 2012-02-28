module Harbor
  module Contrib
    module Translations
      class Translation < Sequel::Model
        
        DEFAULT_SCOPE = "default"
        
        def get(key, locale, scope = DEFAULT_SCOPE)
          if keys = redis.smembers(scope)
            if translation = keys[key]
              translation[2]
            else
              cache(key, locale, scope)
            end
          else
            # The scope wasn't found in redis, so look at the database...
            cache(key, locale, scope)
          end
        end
        
        private
        def cache(key, locale, scope)
          # Not found in redis...
          translations = all(:scope => scope)
          # Put 'em in redis...
          # return the actual entry
        end
        
      end
    end
  end
end