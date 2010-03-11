module Harbor
  module Contrib
    class Stats
      class PageViewReconciler
        
        attr_accessor :logger
        
        def run
          
          # setup our queue of apache requests
          logger.info "Filling the queue with apache requests (this could take a while)"
          queue = RequestQueue.new
          logger.info "No apache requests found, you may need to run the apache_importer before reconciling page views." && break unless queue.size > 0

          # Pull in the table in blocks of 1000 and work on those blocks at a time, better than trying to do it all at once
          page_view_size = repository.adapter.query('select count(*) from page_views').first
          block_size = 1000
          loops = (page_view_size / block_size) + 1
          
          invalid_date = repository.adapter.query('select distinct created_at from page_views order by created_at asc limit 1').first + 1/60000.0

          query = <<-SQL
            select *,ctid from page_views
            where created_at <= ?
            order by ctid asc
            limit ? offset ?
          SQL

          non_matches = 0
          matches = 0
          loops.times do |i|
            logger.info "Batch #{i}:"
            page_views = repository.adapter.query(query, invalid_date, block_size, block_size * i)

            # ctid, remote_ip, request_method, uri, referrer, date
            page_views.map { |v| PageViewRequest.new(v.ctid, nil, nil, v.uri, v.referrer == "/" ? "-" : v.referrer, v.created_at, v.session_id) }.each_with_index do |page_view, j|
              match = queue.expanded_search(page_view)
              if match
                logger.info "\tMatch found for page view #{i}#{j} with CTID #{page_view.id} -- #{match.id} -- QueueSize: #{queue.size}"
                page_view.update!(match.remote_ip, match.request_date)
                match.mark_as_processed!
                matches += 1
              else
                logger.info "\tNo match found for page view #{i}#{j} with CTID #{page_view.id}"
                non_matches += 1
              end
            end
          end

          logger.info "Matches: #{matches}"
          logger.info "NonMatches: #{non_matches}"
          logger.info "Ratio (M/N): #{matches / non_matches.to_f}"
          
          exit!(0)
          
        end
        
      end
    end
  end
end