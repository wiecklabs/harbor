module Harbor
  class Locale
    
    class << self
      def register(locale)
        @@active_locales ||= {}
        @@active_locales[locale.culture_code] = locale
      end

      def [](culture_code)
        @@active_locales[culture_code]
      end

      def active_locales
        @@active_locales
      end

      def flush!
        @@active_locales = {}
      end

      def default
        active_locales[default_culture_code]
      end

      def default_culture_code
        @@default_culture_code ||= "en-US"
      end

      def default_culture_code=(value)
        @@default_culture_code = value
      end
      
    end

    attr_accessor :culture_code, :decimal_formats, :time_formats, :date_formats
    attr_accessor :wday_names, :wday_abbrs, :month_names, :month_abbrs
    attr_reader :entries
    
    def initialize
      @entries = {}
    end
    
    def ==(other_locale)
      [
        culture_code == other_locale.culture_code,
        abbreviation == other_locale.abbreviation,
        description == other_locale.description
      ].all?
    end
    
    #
    # Sets a specific place to a replacement
    # 
    # @param [string] path to store as key, 'key' or 'path/key'
    # @param [string] replacement string to replace the path with
    def set(path, replacement)
      @entries[path] = replacement
    end
    
    
    #
    # Retrieves a replacement by path
    #
    # @param [string] path to retrieve from the stored replacements
    def get(path)
      @entries[path]
    end
    
    
    #
    # Loads a hash into the available replacements
    #
    # @param [Hash <String => String>] replacements_hash to store and retrieve translations from
    def load(replacements_hash)
      @entries.merge!(replacements_hash)
    end
    
    
    #
    # Given a path, perform the translation calling localize() where appropriate
    # 
    # @param [String] path to retrieve from @entries
    # @param [Hash <Symbol => String>] args hash retrieve named interpolation values from
    def translate(path, interpolation_hash = nil)
      interpolate((get(path) || search(path) || path), interpolation_hash)
    end
    
    
    #
    # Given an object, perform the appropriate localization.  When a type-specific localization cannot be performed
    # localize() calls object.to_s and returns.
    #
    # @param [Object] object to attempt to localize
    # @param [Symbol] variation of format to use, defaults to :default
    def localize(object, variation = :default)
      case object
      when ::Date
        format_date(object, variation)
      when ::Time
        format_time(object, variation)
      when ::DateTime
        format_date_time(object, variation)
      when ::BigDecimal
        format_decimal(object, variation)
      when ::Float
        format_decimal(object, variation)
      else
        object.to_s
      end
    end
    
    private
    
    def format_date(date, variation)
      date.strftime @date_formats[variation]
    end
    
    def format_time(time, variation)
      time.strftime @time_formats[variation]
    end
    
    def format_date_time(date_time, variation)
      date_time.strftime time_formats[variation]
    end
    
    def format_decimal(float, variation)
      decimal_formats[variation] % float
    end
    
    def search(path)
      result = nil
      path_prefix = path.split("/")
      until result || path_prefix.empty?
        result = get(path_prefix.join("/"))
        path_prefix.shift
      end
      result
    end
    
    def interpolate(string, interpolation_hash)
      return string if interpolation_hash.nil? || interpolation_hash.empty?
      interpolation_hash.each_pair do |key, value|
        pattern = "{{" + key.to_s + "}}"
        string.gsub! pattern, localize(value)
      end
      string
    end
    
  end
end

require Pathname(__FILE__).dirname + "locales/en_us"
require Pathname(__FILE__).dirname + "locales/en_au"