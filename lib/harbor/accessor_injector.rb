module Harbor
  module AccessorInjector

    def inject(options = {})
      options.each { |key, value| send("#{key}=", value) }
      self
    end

  end
end