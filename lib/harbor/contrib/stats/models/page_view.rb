module Harbor
  module Contrib
    class Stats
      class PageView

        # Query to create page_view table
        CREATE_PAGE_VIEWS = <<-SQL.gsub(/(^\s+)|(\s+$)/, "").freeze
          create table page_views (
            created_at timestamp without time zone default 'now()',
            session_id character varying(36),
            uri text,
            referrer text
          );
        SQL

        # Query to drop page_view table
        DROP_PAGE_VIEWS = "drop table page_views".freeze

        # Query to insert into page_view table
        INSERT = "insert into page_views (session_id, uri, referrer) values (?, ?, ?)".freeze

        def self.create_table!
          raise NotImplementedError.new("You must implement an ORM specific create_table! method")
        end

        def self.drop_table!
          raise NotImplementedError.new("You must implement an ORM specific drop_table! method")
        end

        def self.create(session_id, uri, referrer)
          raise NotImplementedError.new("You must implement an ORM specific create method")
        end

      end
    end
  end
end