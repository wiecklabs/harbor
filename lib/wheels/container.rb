require 'set'

module Wheels
  class Container
  
    def initialize
      @services = {}
      @dependencies = {}
    end
  
    def get(name, optional_properties = {})
      raise ArgumentError.new("#{name} is not a registered service name") unless @services.key?(name)
      service = @services[name].new
      dependencies(name).each do |dependency|
        service.send("#{dependency}=", get(dependency, optional_properties))
      end
    
      optional_properties.each_pair do |k,v|
        writer = "#{k}="
        service.send(writer, v) if service.respond_to?(writer)
      end
    
      service
    end
  
    def register(name, type)
      type_dependencies = dependencies(name)
      type_methods = type.instance_methods.grep(/\=$/)
    
      @services.each do |service_name, service_type|      
        if service_type.instance_methods.include?("#{name}=")
          dependencies(service_name) << name
        end
      
        if type_methods.include?("#{service_name}=")
          type_dependencies << service_name
        end
      end
    
      @services[name] = type
    
      self
    end
  
    private
    def dependencies(service)
      @dependencies[service] ||= Set.new
    end
  end
end