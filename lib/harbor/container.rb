require 'set'

module Harbor
  ##
  # Harbor::Container is an inversion of control container for simple
  # dependency injection. For more information on dependency injection, see
  # http://martinfowler.com/articles/injection.html.
  # 
  # Simple Example:
  # 
  #   services = Harbor::Container.new
  #   services.set("mailer", Harbor::Mailer)
  # 
  #   class Controller
  #     attr_accessor :mailer
  #   end
  # 
  #   services.set("Controller", Controller)
  # 
  #   services.get("Controller") # => #<Controller: @mailer=#<Mailer>>
  ##
  class Container
    
    class ServiceRegistration

      attr_reader :name, :service, :initializers

      def initialize(name, service)
        @name, @service = name, service
        @initializers = Set.new
      end

    end

    def initialize #:nodoc:
      @services = {}
      @dependencies = {}
    end

    ##
    # Retrieve a service by name from the set of registered services, initializing
    # any dependencies from the container, and optionally setting any additional
    # properties on the service.
    # 
    #   class Controller
    #     attr_accessor :request, :response, :mailer
    #   end
    # 
    #   services.get("Controller", :request => Request.new(env), :response => Response.new(request))
    ##
    def get(name, optional_properties = {})
      raise ArgumentError.new("#{name} is not a registered service name") unless set?(name)
      service_registration = @services[name]
      service = service_registration.service.is_a?(Class) ? service_registration.service.new : service_registration.service

      dependencies(name).each do |dependency|
        service.send("#{dependency}=", get(dependency, optional_properties))
      end

      optional_instances = {}
      optional_properties.each_pair do |k,v|
        instance = v.is_a?(Class) ? v.new : v
        optional_instances[k] = instance
      end

      optional_instances.each_pair do |k, v|
        writer = "#{k}="
        service.send(writer, v) if service.respond_to?(writer)
        optional_instances.each_pair do |k2,v2|
          next if k2 == k || !v2.respond_to?(writer)
          v2.send(writer, v)
        end
      end

      service_registration.initializers.each do |initializer|
        initializer.call(service)
      end

      service
    end

    def method_missing(method, *args, &block)
      if method.to_s =~ /^(.*)\=$/
        set($1, *args, &block)
      else
        if set?(method.to_s)
          get(method.to_s, args[0] || {})
        else
          raise NoMethodError.new("undefined method '#{method}' for #{self}", method)
        end
      end
    end

    ##
    # Register a service by name, with an optional initializer block.
    # 
    #   services.set("mail_server", Harbor::SendmailServer.new(:sendmail => "/sbin/sendmail"))
    #   services.set("mailer", Harbor::Mailer)
    #   services.get("mailer") # => #<Harbor::Mailer @from=nil @mail_server=#<SendmailServer...>>
    # 
    #   services.set("mailer", Harbor::Mailer) { |mailer| mailer.from = "admin@example.com" }
    #   services.get("mailer") # => #<Harbor::Mailer @from="admin@example.com" @mail_server=#<SendmailServer...>>
    ##
    def set(name, service, &setup)

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

      @services[name] = ServiceRegistration.new(name, service)
      @services[name].initializers << setup if setup

      service
    end

    def set?(name)
      @services.key?(name)
    end
    
    def register(*args)
      raise NoMethodError.new("DEPRECATED: Harbor::Container#register")
    end
    
    def registered?(*args)
      raise NoMethodError.new("DEPRECATED: Harbor::Container#registered?")
    end
    
    def empty?
      @services.empty?
    end

    private
    def dependencies(service)
      @dependencies[service] ||= Set.new
    end
  end
end
