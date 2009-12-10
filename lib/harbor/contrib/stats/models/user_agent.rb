require 'ipaddr'
module Harbor
  module Contrib
    class Stats

      class UserAgent
        # Query to create user_agents table
        CREATE_USER_AGENTS = <<-SQL.gsub(/(^\s+)|(\s+$)/, "").freeze
        create table user_agents (
          created_at timestamp without time zone default 'now()',
          session_id character varying(36),
          remote_ip inet,
          raw text,
          browser text,
          version text
        );
        SQL

        # Query to drop user_agents table
        DROP_USER_AGENTS = "drop table user_agents".freeze

        # Query to insert into user_agents table
        INSERT = <<-SQL.gsub(/(^\s+)|(\s+$)/, "").freeze
          insert into user_agents (session_id, remote_ip, raw, browser, version)
          select ?, ?, ?, ?, ? where not exists(select 1 from user_agents where session_id = ?)
        SQL

        # Query to fetch user_agent by session_id
        GET = "select * from user_agents where session_id = ?".freeze

        def self.create_table!
          raise NotImplementedError.new("You must implement an ORM specific create_table! method")
        end

        def self.drop_table!
          raise NotImplementedError.new("You must implement an ORM specific drop_table! method")
        end

        def self.create(session_id, remote_ip, user_agent)
          raise NotImplementedError.new("You must implement an ORM specific create method")
        end

        def self.get(session_id)
          raise NotImplementedError.new("You must implement an ORM specific get method")
        end

      end

    end
  end
end