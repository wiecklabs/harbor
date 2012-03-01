##
# Generic URL helpers, such as merging query strings.
##
module Harbor
  module Contrib
    module Translations
      module Helpers
        ##
        # Takes a string to translate and interpolates args.
        ##
        def t(key, *args)
          key % args
        end
      end # Helpers
    end # Translations
  end # Contrib
  
#  class ViewContext
#    include Helpers::Contrib::Translations::Helpers
#  end

end # Harbor
