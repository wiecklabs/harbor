require "redis"
require "uuid"

## TODO: Which is faster under JRuby, YAML or JSON?
require "yaml"

module Harbor
  module Contrib
    class Session
      ##
      # This class provides Redis backed in-memory session support. You can use it
      # instead of the builtin Harbor::Session::Cookie by doing:
      # 
      #   Harbor::Session.configure do |session|
      #     session[:store] = Harbor::Contrib::Session::Redis
      #   end
      #
      ## TODO: Currently there is no support for configuring non-default options for the
      # redis connection. So this is not appropriate for production use at this point
      # (unless you're running everything from a single server I guess).
      ##
      class Redis < Harbor::Session::Abstract

        # This is part of the Session Store API
        def self.load_session(delegate, session_id, request = nil)
          if session_id.blank? || !(data = redis.get(session_id))
            session_id = uuid.generate.freeze
            data = { :session_id => session_id, :updated_at => Time::now }
            redis.set(session_id, dump(data))
            data
          else
            load(data)
          end
        end

        # This is part of the Session Store API
        def self.commit_session(data, request)
          session_id = data[:session_id]
          data[:updated_at] = Time::now
          redis.set(session_id, dump(data))
          redis.expire(session_id, expire_after) if expire_after
          session_id
        end
        
        private
        
        def self.expire_after
          @expire_after ||= Harbor::Session.options[:expire_after]
        end
        
        def self.uuid
          @uuid ||= UUID.new
        end
        
        def self.redis
          @redis ||= if sock = Harbor::Session.options[:sock]
            ::Redis.new(:path => sock)
          else
            host = Harbor::Session.options[:host] || "localhost"
            port = Harbor::Session.options[:port] || 6379
            ::Redis.new(:host => host, :port => port)
          end
        end
        
        def self.dump(data)
          YAML::dump data
        end
        
        def self.load(data)
          YAML::load data
        end
      end
    end
  end
end