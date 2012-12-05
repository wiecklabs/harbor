#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::Container do

  it "must instantiate a registered class" do
    container = Harbor::Container.new
    service = Class.new
    container.register("service", service)
    container.get("service").must_be_kind_of service
  end

  it "must return registered instances" do
    container = Harbor::Container.new
    service = Class.new do
      attr_accessor :component
    end
    instance = service.new
    container.register("service", instance)

    container.get("service").must_be_same_as instance
  end

  it "must instantiate a registered class with sub-components" do
    container = Harbor::Container.new

    service = Class.new do
      attr_accessor :component
    end
    component = Class.new

    container.register("service", service)
    container.register("component", component)

    instance = container.get("service")

    instance.must_be_kind_of service
    instance.component.must_be_kind_of component
  end

  it "must instantiate registered services with get() components" do
    container = Harbor::Container.new

    service = Class.new do
      attr_accessor :component
    end
    component = Class.new

    container.register("service", service)
    component_instance = component.new

    instance = container.get("service", :component => component_instance)

    instance.must_be_kind_of service
    instance.component.must_be_kind_of component
    instance.component.must_be_same_as component_instance
  end

  it "must execute setup blocks" do
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
    instance.component.must_be_kind_of component
    instance.setup.must_equal true
  end

end