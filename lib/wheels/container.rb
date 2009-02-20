require 'set'

module Wheels
  class Container

    def initialize
      @services = {}
      @dependencies = {}
    end

    def get(name, optional_properties = {})
      raise ArgumentError.new("#{name} is not a registered service name") unless @services.key?(name)
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

    private
    def dependencies(service)
      @dependencies[service] ||= Set.new
    end
  end
end