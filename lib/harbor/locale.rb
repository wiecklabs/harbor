require "java"

module Harbor
  class Locale

    def self.[](culture_code)
      unless @locales
        @locales = {}

        java.util.Locale.available_locales.each do |locale|
          @locales[locale.to_s] = locale
        end
      end

      @locales[culture_code]
    end

    def self.active_locales
      @active_locales ||= []
    end

    def self.activate!(*culture_codes)
      @active_locales = culture_codes.map { |culture_code| self[culture_code] }
    end

    def self.default
      @default ||= self[default_culture_code]
    end

    def self.default_culture_code
      @default_culture_code ||= "en_US"
    end

    def self.default_culture_code=(value)
      @default_culture_code = value
    end

    private_class_method :new
  end
end
