require 'harbor/contrib/translations/models/translation_chain'

##
# Generic URL helpers, such as merging query strings.
##
module Harbor::ViewContext::Helpers::Translation

    @@translator ||= Harbor::Contrib::Translations::TranslationChain.new

    ##
    # Takes a string to translate and interpolates args.
    ##
    def t(locale, key)
      @@translator.get(locale, key)
    end

end # Harbor
