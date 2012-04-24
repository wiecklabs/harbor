require "data_objects"
require 'ipaddr'
require 'yaml'

class Harbor
  module Contrib
    class Session
      ##
      # This is a database backed session handle for DataObjects. You can use it
      # instead of the builtin Harbor::Session::Cookie by doing:
      # 
      #   Harbor::Session.configure do |session|
      #     session[:store] = Harbor::Contrib::Session::DataObjects
      #     session[:connection_uri] = 'sqlite3://session.db'
      #   end
      ##
      class DataObjects < Harbor::Session::Abstract
        class UnsupportedDatabaseError < StandardError; end
        
        class SessionHash 
          def initialize(raw)
            @raw = raw
            @data = nil
            @dirty = false
          end
          
          def [](key)
            if [:session_id, :user_id, :remote_ip, :user_agent_raw].include?(key)
              @raw[key]
            else
              load_data![key]
            end
          end

          def []=(key, value)
            raise ArgumentError.new("You cannot manually set the session_id for a session.") if key == :session_id

            @dirty = true
            if [:session_id, :user_id, :remote_ip, :user_agent_raw].include?(key)
              @raw[key] = value
            else
              load_data![key] = value
            end
          end
          
          def dirty?
            @dirty
          end
          
          def data_loaded?
            ! @data.nil?
          end
          
          def load_data!
            return @data if data_loaded?
            
            @data = DataObjects.load(@raw[:data])
          end

          def clear
            @data = {}
            @raw[:user_id] = nil
            @dirty = true
          end
          
          def to_hash
            @data
          end
        end

        def self.load_session(delegate, cookie, request = nil)
          # create_session_table unless session_table_exists?
          
          if cookie && cookie.strip != ''
            raw_session = if expire_after = Harbor::Session.options[:expire_after]
              get_raw_session(cookie, Time.now - expire_after)
            else
              get_raw_session(cookie)
            end
          end
          
          raw_session ||= create_session(delegate, {}, request)

          SessionHash.new(raw_session)
        end

        def self.commit_session(data, request)
          session_id = data[:session_id]
        
          if data.dirty?
            user_id = data[:user_id]
            statement = "UPDATE sessions SET data = ?, user_id = ?, updated_at = ? WHERE id = ?;"
            execute(statement, self.dump(data.to_hash), user_id, Time.now, session_id)
          end
          
          session_id
        end
        
        def self.session_table_exists?        
          return @table_exists unless @table_exists.nil?
          
          with_connection do |connection|
            cmd = connection.create_command(session_table_exists_sql)
            reader = cmd.execute_reader
            
            @table_exists = (reader.next! != false)
            
            reader.close
          end
          
          @table_exists
        end
        
        def self.create_session_table
          return if (@table_exists == true)
          
          with_connection do |connection|
            cmd = connection.create_command(create_session_table_sql)
            cmd.execute_non_query
          end
          
          @table_exists = true
        end
        
        def self.create_session(delegate, data = {}, request = nil)
          session_id = `uuidgen`.chomp
          
          user_id = data.delete(:user_id)
          remote_ip = request ? request.remote_ip : nil
          user_agent_raw = request ? request.env["HTTP_USER_AGENT"] : nil
          
          data = self.dump(data)
          now = Time.now
          
          # We split in case X-Forwarded-For is a list, and rescue any errors
          # by setting the IP to 0.0.0.0 (which we'll treat as 'unknown').
          clean_ip = IPAddr.new(remote_ip.split(/,/, 2).first).to_s rescue '127.0.0.1'
          
          statement = "INSERT INTO sessions (id, data, user_id, remote_ip, user_agent_raw, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?);"
          execute(statement, session_id, data, user_id, clean_ip, user_agent_raw, now, now)
          delegate.session_created(session_id, remote_ip, user_agent_raw)
          
          {:session_id => session_id, :data => data, :user_id => user_id, :remote_ip => clean_ip, :user_agent_raw => user_agent_raw}
        end
        
        def self.get_raw_session(cookie, updated_at=nil)
          query = "SELECT id, data, user_id, remote_ip, user_agent_raw FROM sessions WHERE id = ? "
          params = [cookie]
          
          if updated_at
            query << ' AND updated_at >= ?'
            params << updated_at
          end
          query << ' LIMIT 1'
        
          raw = {}
          with_connection do |connection|
            cmd = connection.create_command(query)
            reader = cmd.execute_reader(*params)
            
            if reader.next!
              raw[:session_id] = reader.values[0]
              raw[:data] = reader.values[1]
              raw[:user_id] = reader.values[2]
              raw[:remote_ip] = reader.values[3]
              raw[:user_agent_raw] = reader.values[4]
            else
              raw = nil
            end
            
            reader.close
          end
          
          raw
        end
        
        def self.dump(value)
          YAML::dump value
        end
        
        def self.load(value)
          YAML::load value
        end
        
        def self.execute(statement, *bind_values)
          with_connection do |connection|
            command = connection.create_command(statement)
            command.execute_non_query(*bind_values)
          end
        end
      
        def self.with_connection
          conn = nil
          begin
            conn = ::DataObjects::Connection.new(Harbor::Session.options[:connection_uri])
            
            return yield(conn)
#          rescue => e
#            DataMapper.logger.error(e.to_s)
#            raise e
          ensure
            conn.close if conn
          end
        end
        
      private
        # TODO we could create some kind of adapter when we get to add more supported DBs
      
        def self.create_session_table_sql
          case scheme
          when :sqlite3
            "CREATE TABLE sessions (id VARCHAR(50) NOT NULL, user_id INTEGER, remote_ip INET, user_agent_raw TEXT, data TEXT, created_at DATETIME, updated_at DATETIME, PRIMARY KEY(id))"
          when :postgres
            "CREATE TABLE sessions (id VARCHAR(50) NOT NULL, user_id INTEGER, remote_ip INET, user_agent_raw TEXT, data TEXT, created_at TIMESTAMP, updated_at TIMESTAMP, PRIMARY KEY(id))"
          else
            raise UnsupportedDatabaseError.new("Only SQLite3 and PostgreSQL are supported at the moment")
          end
        end
      
        def self.session_table_exists_sql
          case scheme
          when :sqlite3
            "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'sessions';"
          when :postgres
            "SELECT * FROM pg_tables WHERE schemaname = 'public' AND tablename = 'sessions';"
          else
            raise UnsupportedDatabaseError.new("Only SQLite3 and PostgreSQL are supported at the moment")
          end
        end
        
        def self.scheme
          @scheme ||= ::DataObjects::URI::parse(Harbor::Session.options[:connection_uri]).scheme.to_sym
        end        
      end
    end
  end
end
