module Harbor
  ##
  # Heplful to include in your config.ru for getting an interative IRB
  # session.
  # 
  #    #!/usr/bin/env ruby
  #    # require app, set up ORM, etc.
  #    
  #    if $0 == __FILE__
  #      Harbor::Console.start
  #    else
  #      run MyApplication
  #    end
  ##
  class Console

    def self.start
      require 'irb'
      require 'irb/completion'
      if ::File.exists? ".irbrc"
        ENV['IRBRC'] = ".irbrc"
      end

      IRB.start
    end

  end
end