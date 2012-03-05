if RUBY_PLATFORM =~ /java/
  require_relative "locale/java"
else
  require_relative "locale/mri"
end

module Harbor
  class Locale
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
  end
end
