module Harbor
  module Contrib
    class Stats
      class Request
        
        attr_accessor :id, :remote_ip, :request_method, :uri, :referrer, :request_date, :session_id

        def initialize(id, remote_ip, request_method, uri, referrer, date, session_id = nil)
          self.id = id
          self.remote_ip = remote_ip
          self.request_method = request_method
          self.uri = uri
          self.referrer = referrer
          self.request_date = DateTime.parse(date.to_s)
          self.session_id = session_id
        end

        def ==(request)
          self.uri == request.uri && self.referrer == request.referrer
        end
        
      end
      
      class ApacheRequest < Request
        
        def mark_as_processed!
          repository.adapter.execute('update apache_requests set processed = ? where id = ?', true, self.id)
        end
        
        def self.create_table!
          unless repository.adapter.storage_exists?('apache_requests')
            repository.adapter.execute(<<-SQL
              create table apache_requests
              (
                id integer, remote_ip inet, request_method varchar, uri text, referrer text, date timestamp, processed boolean
              )
            SQL
            )
          end
        end
        
        def self.drop_table!
          if repository.adapter.storage_exists?('apache_requests')
            repository.adapter.execute('drop table apache_requests')
          end
        end
        
        def self.create(id, ip_address, request_type, uri, referrer, date)
          
          insert_query = <<-SQL
            insert into apache_requests
            values(?,?,?,?,?,?,?)
          SQL
          
          repository.adapter.execute(insert_query, id, ip_address, request_type, uri, referrer, date, nil)
        
        end
        
        def self.all_unprocessed(limit=nil, offset=nil)
          query = <<-SQL
            select * 
            from apache_requests 
            where processed is null 
            order by date asc
            limit ?
            offset ?
          SQL
          repository.adapter.query(query, limit, offset)
        end
        
        def self.unprocessed_count
          query = <<-SQL
            select count(*)
            from apache_requests 
            where processed is null
          SQL
          repository.adapter.query(query).first
        end
        
      end
      
      class PageViewRequest < Request

        UPDATE_QUERY = <<-SQL
          update page_views
          set created_at = ?
          where ctid = ?
        SQL

        def update!(remote_ip, date)
          repository.adapter.execute(UPDATE_QUERY, date, self.id)
          if repository.adapter.query('select remote_ip from user_agents where session_id = ?', self.session_id).first == '127.0.0.1'
            repository.adapter.execute('update user_agents set remote_ip = ? where session_id = ?', remote_ip, self.session_id)
          end
        end
        
      end
      
    end
  end
end