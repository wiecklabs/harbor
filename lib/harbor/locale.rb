module Harbor
  class Locale

    def self.[](culture_code)
      unless @locales
        @locales = {}

        ::File.read(Pathname(__FILE__).dirname + "locales.txt").split("\n").each do |line|
          next if line =~ /^\s*(\#.*)?$/
          values = line.split(/\|/).map { |value| value.strip }
          @locales[values[1]] = Locale.new(values[1], values[0], values[2])
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
      @default_culture_code ||= "en-US"
    end

    def self.default_culture_code=(value)
      @default_culture_code = value
    end

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
  end
end
