module Harbor
  module Contrib
    class Stats
      class ApacheImporter
        
        attr_accessor :logger, :apache_file
        
        def initialize(apache_file)
          self.apache_file = apache_file
        end
        
        def run
          
          apache_regex = /(.*) - - \[(.*)\] \"(.*) (.*) .*\" .* .* \"(.*)\" \".*\"/
          
          invalid_date = repository.adapter.query('select distinct created_at from page_views order by created_at asc limit 1').first + 1/60000.0

          # Unique URIs from page_views, these are the only ones we want to look at in the Apache logs
          logger.info "Invalid date: #{invalid_date.to_s}"
          unique_uris = repository.adapter.query('select distinct uri from page_views where created_at <= ?', invalid_date)
          logger.info "#{unique_uris.size} unique URIs found!"
          
          Harbor::Contrib::Stats::ApacheRequest.create_table!

          repository.adapter.execute('truncate table apache_requests')

          i, j = 0, 0
          f = ::File.new(self.apache_file)
          while (line = f.readline)
            i+=1
            logger.info "Apache lines parsed: #{i}, Requests imported: #{j}" if i%1000 == 0
            if line =~ apache_regex
              ip_address = $1
              request_type = $3
              uri = $4
              referrer = $5
              date = DateTime.parse($2.sub(":"," "))
              break if date >= DateTime.parse('2010-02-27 00:00:00')
              next unless unique_uris.include?(uri) && date > invalid_date
              j += 1
              Harbor::Contrib::Stats::ApacheRequest.create(j, ip_address, request_type, uri, referrer, date)
            end
          end
          logger.info "Parsing complete!"
          logger.info "Apache lines parsed: #{i}, Requests imported: #{j}"
          exit!(0)
          
        end
        
      end
    end
  end
end