module Harbor
  module Contrib
    class Stats
      module DataMapper

        class PageView < Harbor::Contrib::Stats::PageView

          def self.create_table!
            repository.adapter.execute(CREATE_PAGE_VIEWS)
          end

          def self.drop_table!
            repository.adapter.execute(DROP_PAGE_VIEWS)
          end

          def self.create(session_id, uri, referrer)
            repository.adapter.execute(INSERT, session_id, uri, referrer)
          end

        end

        class UserAgent < Harbor::Contrib::Stats::UserAgent
          def self.create_table!
            repository.adapter.execute(CREATE_PAGE_VIEWS)
          end

          def self.drop_table!
            repository.adapter.execute(DROP_PAGE_VIEWS)
          end

          def self.create(session_id, remote_ip, user_agent)
            # We split in case X-Forwarded-For is a list, and rescue any errors
            # by setting the IP to 0.0.0.0 (which we'll treat as 'unknown').
            clean_ip = IPAddr.new(ip.split(/,/, 2).first).to_s rescue '127.0.0.1'

            repository.adapter.execute(INSERT, session_id, clean_ip, user_agent, "", "", session_id)
          end

          def self.get(session_id)
            repository.adapter.query(GET, session_id)
          end

        end

        class ::Session #:nodoc:
          def user_agent
            Harbor::Contrib::Stats::DataMapper::UserAgent.get(self.id)
          end
        end

      end
    end
  end
end