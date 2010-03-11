module Harbor
  module Contrib
    class Stats
      class RequestQueue < Array
        
        attr_accessor :unprocessed_count, :offset
        
        BLOCK_SIZE = 10000
        
        def initialize
          self.unprocessed_count = Harbor::Contrib::Stats::ApacheRequest.unprocessed_count
          self.offset = 0
          fill_queue!(BLOCK_SIZE, 0)
        end

        def expanded_search(page_view)
          self.each_with_index do |request, i|
            if request == page_view
              return self.delete_at(i)
            end
          end
          nil
          # self.offset += BLOCK_SIZE
          # puts "Expanding queue by #{BLOCK_SIZE}, offset: #{self.offset}"
          # fill_queue!(BLOCK_SIZE, self.offset)
          # expanded_search(page_view)
        end

        def fill_queue!(limit, offset)
          self << Harbor::Contrib::Stats::ApacheRequest.all_unprocessed(limit, offset).map { |v| ApacheRequest.new(v.id, nil, nil, v.uri, v.referrer, v.date) }
          self.flatten!
          return true
        end

      end
    end
  end
end