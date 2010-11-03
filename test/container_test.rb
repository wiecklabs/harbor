require "pathname"
require Pathname(__FILE__).dirname + "helper"

class ContainerTest < Test::Unit::TestCase

  def test_registered_class_instantiation
    container = Harbor::Container.new
    service = Class.new
    container.register("service", service)
    assert_kind_of(service, container.get("service"))
  end
   
  def test_registered_instance
    container = Harbor::Container.new
    service = Class.new do
      attr_accessor :component
    end
    instance = service.new
    container.register("service", instance)
    assert_equal(instance, container.get("service"))
  end

  def test_registered_class_with_components
    container = Harbor::Container.new
 
    service = Class.new do
      attr_accessor :component
    end
    component = Class.new
 
    container.register("service", service)
    container.register("component", component)
 
    instance = container.get("service")
    assert_kind_of(service, instance)
    assert_kind_of(component, instance.component)
  end

  def test_registered_class_with_optional_arguments
    container = Harbor::Container.new
 
    service = Class.new do
      attr_accessor :component
    end
    component = Class.new

    container.register("service", service)
    component_instance = component.new
    
    instance = container.get("service", :component => component_instance)
    assert_kind_of(service, instance)
    assert_kind_of(component, instance.component)
    assert_equal(component_instance, instance.component)
  end
  
  def test_setup_block
    container = Harbor::Container.new

    service = Class.new do
      attr_accessor :component, :setup
    end

    component = Class.new
    container.register("component", component)
    container.register("service", service) do |s|
      s.setup = true
    end

    instance = container.get("service")
    assert_kind_of(component, instance.component)
    assert(instance.setup)
  end

end