require 'harbor/locale'

module Harbor
  class I18n
    attr_reader :locales
    PATH_SEPERATOR = "."
    
    class InvalidLocale < StandardError; end
    
    def self.parse(env)
      # TODO: make it check session[:locale] and mebbe request string? (not here, somewheres else)
      return new(Harbor::Locale.default) if env['HTTP_ACCEPT_LANGUAGE'].nil? || env['HTTP_ACCEPT_LANGUAGE'] == ''

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
      locale_preferences.map! { |i| Harbor::Locale[i[0]] }

      new locale_preferences.compact
    end

    def initialize(*locales)
      @locales = locales.compact.flatten
      # TODO ensure we're dealing with Harbor::Locale objects, and if we're not, bark
      @locales << Harbor::Locale.default if @locales.empty?
    end
    
    def inspect
      "<Harbor::I18n @locales=#{@locales.inspect}>"
    end
    
    # for translating a string or count
    def translate(path)
      
    end
    
    # for working with native representations of data types (dates, floats, times)
    def localize(object, variation = nil)
      
    end
    
    def ==(other)
      locales == other.locales
    end
    
    
  end
end
