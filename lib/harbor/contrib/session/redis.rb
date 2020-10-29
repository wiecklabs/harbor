require "redis_directory"

if RUBY_PLATFORM =~ /java/
  require "java"
else
  require "uuid"
end

## TODO: Which is faster under JRuby, YAML or JSON?
# Right now switching the dump/load methods to JSON breaks things. Which is weird.
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
            session_id = generate_uuid
            data = { :session_id => session_id, :updated_at => Time::now, :client_name => client_name }
            redis.set(session_id, dump(data))
            redis.expire(session_id, expire_after)

            remote_ip = request ? request.remote_ip : nil
            user_agent_raw = request ? request.env["HTTP_USER_AGENT"] : nil

            delegate.session_created(session_id, remote_ip, user_agent_raw)

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
          redis.expire(session_id, expire_after)
          session_id
        end

        private

        def self.expire_after
          #Set session timeout to 1 week (604800 seconds)
          @expire_after ||= (Harbor::Session.options[:expire_after] || 604800)
        end

        if RUBY_PLATFORM =~ /java/

          def self.generate_uuid
            java.util.UUID.randomUUID.to_s.freeze
          end

        else

          def self.generate_uuid
            @uuid_generator ||= UUID.new
            @uuid_generator.generate.freeze
          end

        end

        def self.client_name
          @client_name ||= begin
            if name = Harbor::Session.options[:name]
              name
            else
              raise ArgumentError.new("You must provide a :name to Harbor::Session::options!")
            end
          end
        end
        
        def self.redis
          @redis ||= if sock = Harbor::Session.options[:sock]
            ::Redis::Directory.new(:path => sock).get("sessions", client_name)
          else
            host = Harbor::Session.options[:host] || "localhost"
            port = Harbor::Session.options[:port] || 6379
            ::Redis::Directory.new(:host => host, :port => port).get("sessions", client_name)
          end
        end

        def self.redis=(connection)
          @redis = connection
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