module Harbor
  class Response
    
    STATS_HEADER = 'X-Harbor-Stats'
    NO_STAT = 'no-stat'

    def no_stat!
      @headers[STATS_HEADER] = NO_STAT
    end

  end
end