warn "\n\nWARNING: Locales are not fully supported on MRI yet"

module Harbor
  class Locale
    attr_reader :country, :language

    def self.[](culture_code)
      @locales ||= {
        'en_US' => self.new('US', 'en')
      }

      @locales[culture_code]
    end

    def initialize(country, language)
      @country, @language = country, language
    end

    def to_s
      @to_s ||= [ country, language ].compact.join("_")
    end
  end
end
