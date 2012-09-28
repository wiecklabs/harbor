class Harbor
  class Configuration < Harbor::Container

    def self.instance
      @instance ||= begin
        instance = self::new(ENV["ENVIRONMENT"] || DEVELOPMENT)
        instance.set("hostname", `hostname`.strip)
        instance
      end
    end

    def initialize(environment = nil)
      super()
      @debug = false
      @environment = environment
    end

    def method_missing(method, *args, &block)
      if method.to_s =~ /^(.*)\=$/
        set($1, *args, &block)
      else
        if set?(method.to_s)
          get(method.to_s, args[0] || {})
        else
          service = Harbor::Configuration.new
          @services[method.to_s] = ServiceRegistration.new(method.to_s, service)
          service
        end
      end
    end

    def environment
      @environment
    end

    def test?
      @environment == TEST
    end

    def development?
      @environment == DEVELOPMENT
    end

    def stage?
      @environment == STAGE
    end

    def production?
      @environment == PRODUCTION
    end

    def load!(path)
      env = Pathname(path)

      host_configs = if hostname =~ /\./
        # If the hostname is something like "stage.demo", then we want to load our
        # configs in order of least specific to most specific. So we want:
        # [ "stage", "demo", "stage.demo" ]
        [ *hostname.split(".").map { |part| "#{part}.rb" } << "#{hostname}.rb" ]
      else
        [ "#{hostname}.rb" ]
      end

      # It could be that the hostname split above duplicates an environment based config name.
      cascade = [ "default.rb", "#{@environment}.rb", *host_configs ].uniq

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

    private

    TEST = "test".freeze
    DEVELOPMENT = "development".freeze
    STAGE = "stage".freeze
    PRODUCTION = "production".freeze
  end
end

def config
  Harbor::Configuration::instance
end
