require "pathname"
require Pathname(__FILE__).dirname + "helper"
require "sequel_test_case"
require "harbor/contrib/translations/models/translation"

module Contrib
  module Translations

    class TranslationTest < SequelTestCase

      def setup
        @translation = Harbor::Contrib::Translations::Translation.new(Redis.new)
      end

      def test_get_all_nils
        result = @translation.get(nil, nil)
        assert(!result)
      end

      def test_non_existant_key
        locale = 'en_us'
        key = 'subscribe'
        assert(!@translation.exists_in_redis?(locale, key))
        assert(!@translation.exists_in_db?(locale, key))

        result = @translation.get(locale, key)
        assert_equal('subscribe', result)
      end

      def test_put
        assert(!@translation.exists_in_redis?('en_us', 'subscribe'))
        @translation.put!('en_us', 'subscribe')
        assert(@translation.exists_in_redis?('en_us', 'subscribe'))
      end

    end
  end
end

