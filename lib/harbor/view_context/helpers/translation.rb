require 'harbor/contrib/translations/models/translation'

##
# Generic URL helpers, such as merging query strings.
##
module Harbor::ViewContext::Helpers::Translation

    @@translator ||= Harbor::Contrib::Translations::Translation.new

    ##
    # Takes a string to translate and interpolates args.
    ##
    def t(locale, key)
      @@translator.get(locale, key)
    end

end # Harbor
