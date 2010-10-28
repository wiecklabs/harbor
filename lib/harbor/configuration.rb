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
    
    ##
    # Register a service by name, with an optional initializer block.
    # 
    #   services.register("mail_server", Harbor::SendmailServer.new(:sendmail => "/sbin/sendmail"))
    #   services.register("mailer", Harbor::Mailer)
    #   services.get("mailer") # => #<Harbor::Mailer @from=nil @mail_server=#<SendmailServer...>>
    # 
    #   services.register("mailer", Harbor::Mailer) { |mailer| mailer.from = "admin@example.com" }
    #   services.get("mailer") # => #<Harbor::Mailer @from="admin@example.com" @mail_server=#<SendmailServer...>>
    ##
    def register(name, service, &setup)
      type_dependencies = dependencies(name)
      type_methods = service.is_a?(Class) ? service.instance_methods.grep(/\=$/) : []

      @services.values.each do |service_registration|
        if service_registration.service.is_a?(Class) && service_registration.service.instance_methods.include?("#{name}=")
          dependencies(service_registration.name) << name
        end

        if type_methods.include?("#{service_registration.name}=")
          type_dependencies << service_registration.name
        end
      end

      @services[name] ||= ServiceRegistration.new(name, service)
      @services[name].initializers << setup if setup

      self
    end
  end
end

def config
  Harbor::Configuration::instance
end