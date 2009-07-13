require "pathname"
require Pathname(__FILE__).dirname + "helper"

describe "Container" do

  it "should create a registered class" do
      container = Harbor::Container.new
      service = Class.new
      container.register("service", service)
      container.get("service").should be_a_kind_of(service)
    end
   
    it "should return a registered service instance" do
      container = Harbor::Container.new
      service = Class.new do
        attr_accessor :component
      end
      container.register("service", service.new)
      container.get("service").should be_a_kind_of(service)
    end
   
    it "should create a registered class with components" do
      container = Harbor::Container.new
   
      service = Class.new do
        attr_accessor :component
      end
      component = Class.new
   
      container.register("service", service)
      container.register("component", component)
   
      instance = container.get("service")
      instance.should be_a_kind_of(service)
      instance.component.should be_a_kind_of(component)
    end
   
    it "should create a registered service with optional arguments" do
      container = Harbor::Container.new
   
      service = Class.new do
        attr_accessor :component
      end
      component = Class.new
   
      container.register("service", service)
   
      instance = container.get("service", :component => component.new)
      instance.should be_a_kind_of(service)
      instance.component.should be_a_kind_of(component)
    end

  it "should return a registered service instance" do
    container = Harbor::Container.new

    service = Class.new do
      attr_accessor :component
      attr_accessor :server
    end
    component = Class.new do
      attr_accessor :mailer
    end
    server = Object.new
    mailer = Object.new

    container.register("service", service)
    container.register("component", component)
    container.register("server", server)

    instance = container.get("service", :mailer => mailer)
    instance.should be_a_kind_of(service)
    instance.server.should == server
    instance.component.should be_a_kind_of(component)
    instance.component.mailer.should == mailer
  end

  it "should create a registerd service with optional arguments in Class form" do
    container = Harbor::Container.new
  
    service = Class.new do
      attr_accessor :component
    end
    component = Class.new
  
    container.register("service", service)
  
    instance = container.get("service", :component => component)
    instance.should be_a_kind_of(service)
    instance.component.should be_a_kind_of(component)
  end
  
  it "should execute a setup block when provided" do
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
    instance.component.should be_a_kind_of(component)
    instance.setup.should be_true
  end
  
  it "should execute all initializers after multiple registrations" do
    container = Harbor::Container.new
  
    service = Class.new do
      attr_accessor :component, :sms_server_initialized, :mail_server_initialized
    end
  
    sms_server_initializer = lambda do |s|
      s.sms_server_initialized = true
    end
  
    mail_server_initializer = lambda do |s|
      s.mail_server_initialized = true
    end
  
    component = Class.new
    container.register("component", component)
    container.register("service", service, &sms_server_initializer)
    container.register("service", service, &mail_server_initializer)
  
    instance = container.get("service")
    instance.component.should be_a_kind_of(component)
    instance.sms_server_initialized.should be_true
    instance.mail_server_initialized.should be_true
  end

end