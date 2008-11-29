module Wheels
  class Console

    def self.start
      require 'irb'
      require 'irb/completion'

      if File.exists? ".irbrc"
        ENV['IRBRC'] = ".irbrc"
      end

      IRB.start
    end

  end
end