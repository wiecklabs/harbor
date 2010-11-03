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
      register("hostname", `hostname`.strip)
      
      host_configs = if hostname =~ /\./
        # If the hostname is something like "stage.demo", then we want to load our
        # configs in order of least specific to most specific. So we want:
        # [ "stage", "demo", "stage.demo" ]
        [ *hostname.split(".").map { |part| "#{part}.rb" } << "#{hostname}.rb" ]
      else
        [ "#{hostname}.rb" ]
      end
      
      # It could be that the hostname split above duplicates an environment based config name.
      cascade = [ "default.rb", "#{ENV["ENVIRONMENT"]}.rb", *host_configs ].uniq
      
      if ENV["DEBUG"] then
        puts "env search cascade is #{cascade.inspect}"
      end
      
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