module Harbor
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