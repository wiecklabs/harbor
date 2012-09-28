require "java"

class Harbor
  class Locale
    def self.[](culture_code)
      @locales ||=
        java.util.Locale.available_locales.each_with_object({}) do |locale, hash|
          hash[locale.to_s] = locale
        end

      @locales[culture_code]
    end

    private_class_method :new
  end
end
