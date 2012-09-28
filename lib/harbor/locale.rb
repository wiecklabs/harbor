if RUBY_PLATFORM =~ /java/
  require_relative "locale/java"
else
  require_relative "locale/mri"
end

class Harbor
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
<<<<<<< HEAD

    def self.register(locale, activate = false)
      registered_locale = self[locale.culture_code] || @locales[locale.culture_code] = locale

      if activate
        @active_locales ||= []
        @active_locales << registered_locale
      end

      registered_locale
    end

    attr_reader :culture_code, :abbreviation, :description, :native_spelling

    def initialize(culture_code, abbreviation, description, native_spelling=nil)
      @culture_code = culture_code
      @abbreviation = abbreviation
      @description = description
      @native_spelling = native_spelling
    end

    def to_s
      @description
    end
=======
>>>>>>> afcda6833a461947da81fee3e28965b762663c3e
  end
end
