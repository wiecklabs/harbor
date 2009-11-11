module Harbor
  ##
  # A simple module to facilitate accessor based injection. This is used by Harbor::Plugin
  # to allow you to easily construct plugins from hashes, i.e.:
  # 
  #   <%= plugin("user/tabs", :user => @user)
  # 
  # It can of course be used 
  # 
  #   class Dog
  #     include Harbor::AccessorInjector
  #     attr_accessor :owner
  #   end
  # 
  #   dog = Dog.new.inject(:owner => "Tom")
  #   dog.owner # => "Tom"
  ##
  module AccessorInjector

    def inject(options = {})
      options.each do |key, value|
        setter = "#{key}="
        send(setter, value) if respond_to?(setter)
      end

      self
    end

  end
end