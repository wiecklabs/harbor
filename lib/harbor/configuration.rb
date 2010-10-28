require "fileutils"
require "pathname"

module Harbor
  class Configuration < Harbor::Container

    def self.instance
      @instance ||= instance = self::new
    end
    
    def initialize
      super
      @debug = false
    end
    
    def load!(path)
      env = Pathname(path)  
      cascade = [ "default.rb", "#{ENV["ENVIRONMENT"]}.rb", "#{`hostname`}.rb" ]
      
      cascade.each do |file|
        configuration_file = Pathname(path) + file
        if ::File.exists?(configuration_file.to_s)
          load configuration_file
        end
      end
    end
    
    def debug!
      @debug = true
    end
    
    def debug?
      @debug
    end
  end
end

def config
  Harbor::Configuration::instance
end

config.load!(Harbor::env_path)