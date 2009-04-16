require 'set'

module Wheels
  ##
  # Wheels::Container is an inversion of control container for simple
  # dependency injection. For more information on dependency injection, see
  # http://martinfowler.com/articles/injection.html.
  # 
  # Simple Example:
  # 
  #   services = Wheels::Container.new
  #   services.register("mailer", Wheels::Mailer)
  # 
  #   class Controller
  #     attr_accessor :mailer
  #   end
  # 
  #   services.register("Controller", Controller)
  # 
  #   services.get("Controller") # => #<Controller: @mailer=#<Mailer>>
  ##
  class Container

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
      raise ArgumentError.new("#{name} is not a registered service name") unless registered?(name)
      registration, setup = @services[name]

      service = registration.is_a?(Class) ? registration.new : registration

      dependencies(name).each do |dependency|
        service.send("#{dependency}=", get(dependency, optional_properties))
      end

      optional_properties.each_pair do |k,v|
        writer = "#{k}="
        service.send(writer, v.is_a?(Class) ? v.new : v) if service.respond_to?(writer)
      end

      setup.call(service) if setup

      service
    end

    ##
    # Register a service by name, with an optional initializer block.
    # 
    #   services.register("mail_server", Wheels::SendmailServer.new(:sendmail => "/sbin/sendmail"))
    #   services.register("mailer", Wheels::Mailer)
    #   services.get("mailer") # => #<Wheels::Mailer @from=nil @mail_server=#<SendmailServer...>>
    # 
    #   services.register("mailer", Wheels::Mailer) { |mailer| mailer.from = "admin@example.com" }
    #   services.get("mailer") # => #<Wheels::Mailer @from="admin@example.com" @mail_server=#<SendmailServer...>>
    ##
    def register(name, type, &setup)
      type_dependencies = dependencies(name)
      type_methods = type.is_a?(Class) ? type.instance_methods.grep(/\=$/) : []

      @services.each do |service_name, service|
        service_type, service_setup = service
        if service_type.is_a?(Class) && service_type.instance_methods.include?("#{name}=")
          dependencies(service_name) << name
        end

        if type_methods.include?("#{service_name}=")
          type_dependencies << service_name
        end
      end

      @services[name] = [type, setup]

      self
    end

    def registered?(name)
      @services.key?(name)
    end

    private
    def dependencies(service)
      @dependencies[service] ||= Set.new
    end
  end
end