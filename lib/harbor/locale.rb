require 'bigdecimal'
##
# = Harbor::Localization
#
# Harbor supports the English-US locale by default, but adding locales (even replacing the default) is easy.
# 
# To configure a new locale, do the following:
# 
#   en_au = Harbor::Locale.new
#   en_au.culture_code        = 'en-AU'
#   en_au.time_formats        = {:long => "%d/%m/%Y %h:%m:%s", :default => "%h:%m:%s"}
#   en_au.date_formats        = {:default => '%d/%m/%Y'}
#   en_au.decimal_formats     = {:default => "%8.2f", :currency => "$%8.2f"}
#   en_au.wday_names          = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
#   en_au.wday_abbrs          = %w(Sun Mon Tue Wed Thur Fri Sat)
#   en_au.month_names         = %w{January February March April May June July August September October November December}
#   en_au.month_abbrs         = %w{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec}
#   
#   Harbor::Locale.register(en_au)
# 
# To load up string replacements into the locale, do:
# 
#   en_au.load({'key' => 'value', ...}) # to load a hash into the locale
#   en_au.set('organization', 'organisation')  # to set an individual key => value pair
# 
# = Features 
# 
# == Path Prefixing
# 
# Sometimes the translated word for "organization" is different depending on
# the context. For example, "organization" when used in the sentence "The user
# belongs to the Initech organization" is different than "organization" when
# used in "The organization of the photos in my library is superb".  To
# support this, Harbor::Locale automatically adds the file path as a prefix to
# whatever you provide to the t() helper.  When specifying a localization,
# take advantage of this by setting string replacements like this:
# 
#   en_au.set('account/new/organization', 'organisation')
#   en_au.set('tasks/organization', 'order')
#   en_au.set('organization', 'organisation')
# 
# When you call t('organization'), Harbor::Locale will search for variations of the path prefix in the
# following order and return the first non-nil value it finds:
# 
#   1. account/new/organization
#   2. new/organization
#   3. organization
# 
# === Named Interpolation 
# 
# Localization sometimes requires interpolating a value into a string.  To
# support this, Harbor::Locale uses a simple {{key}} syntax in it's t()
# helper.  For example:
# 
#   <%= t('{{birthday}} is my birthday', :birthday => Date.today) %>
# 
# will output:  "September 30 1983 is my birthday".
# 
# NOTE: Harbor::Locale does NOT support positioned or sprintf-style
# interpolation because the syntax is annoyingly hard and not eye-parseable no
# matter how l33t you are. Always use Named Interpolation. You'll thank us
# later. If you really really want it, do:
# 
#  <%= t('{{birthday}} is my birthday', :birthday => ("%Y/%m/%d" % Date.today))
# 
# But, to be honest, you'd be better off registering a date_format with your locale like this:
# 
#   en_au.date_formats[:long] = "%Y/%m/%d"
# 
# ...and then specifically localizing your data before performing the interpolation:
# 
#  <%= t('{{birthday}} is my birthday', :birthday => l(Date.today, :long))
# 
# === Data Type Localization 
# TODO: write this section
# 
# === View Helpers
# TODO: write this section
# 
##
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
        @@active_locales = []
      end

      def default
        self[default_culture_code]
      end

      def default_culture_code
        @@default_culture_code ||= "en-US"
      end

      def default_culture_code=(value)
        @@default_culture_code = value
      end
      
      def parse(env)
        return self.default if env['HTTP_ACCEPT_LANGUAGE'].nil? || env['HTTP_ACCEPT_LANGUAGE'] == ''

        locale_preferences = env['HTTP_ACCEPT_LANGUAGE'].split(',')
        locale_preferences.map! do |locale|
          locale = locale.split ';q='
          if 1 == locale.size
            [locale[0], 1.0]
          else
            [locale[0], locale[1].to_f]
          end
        end
        locale_preferences.sort! { |a, b| b[1] <=> a[1] }
        self[locale_preferences[0][0]] || self.default
      end
      
      
    end

    class LocalizedString < String
      
      def initialize(raw, translated = false)
        raise ArgumentError, "Harbor::Locale::LocalizedString was initialized with #{raw.inspect} which wasn't a String" unless raw.is_a?(String)
        # intentionally allowing blank values
        
        @raw = raw
        @translated = translated
      end
      
      def translated?
        @translated
      end
      
      def to_s
        translated? ? @raw : "<span class='untranslated'>#{@raw}</span>"
      end
      
      def gsub(key, value)
        @raw.gsub(key, value)
      end
      
      def gsub!(key, value)
        @raw.gsub!(key, value)
      end
      
      def ==(other)
        other.to_s == to_s
      end
      
      def inspect
        "Harbor::Locale::LocalizedString @raw=#{@raw.inspect} @translated=#{translated?}"
      end
    end

    attr_accessor :culture_code, :decimal_formats, :time_formats, :date_formats
    attr_accessor :wday_names, :wday_abbrs, :month_names, :month_abbrs
    attr_reader :entries
    
    def initialize
      @entries = {}
    end
    
    def ==(other_locale)
      culture_code == other_locale.culture_code
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
      retrieval = @entries[path]
      # retrieval ? LocalizedString.new(retrieval, true) : nil
    end
    
    
    #
    # Merges a hash into the available replacements
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
      interpolate((search(path) || get(path) || LocalizedString.new(path.split("/")[-1])), interpolation_hash)      
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
    
    def inspect
      "<Harbor::Locale[#{culture_code.inspect}]>"
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
      result ? LocalizedString.new(result, true) : result
    end
    
    def interpolate(string, interpolation_hash)
      return string if interpolation_hash.nil? || interpolation_hash.empty?
      interpolation_hash.each_pair do |key, value|
        pattern = "{{" + key.to_s + "}}"
        string.gsub!(pattern, localize(value))
      end
      string
    end
    
  end
end

require Pathname(__FILE__).dirname + "locales/en_us" # Harbor-wide default locale