require "pathname"
require Pathname(__FILE__).dirname + "helper"
require "sequel_test_case"
require "harbor/contrib/translations/models/translation"

module Contrib
  module Translations

    class TranslationTest < SequelTestCase

      LOCALE_EN = 'en_us'
      LOCALE_ES = 'es_mx'
      KEY = 'subscribe'
      VAL = 'you should subscribe'

      attr_accessor :backend

      def setup
        redis = Redis.new
        backend = I18n::Backend::KeyValue.new(redis)
        @translation = Harbor::Contrib::Translations::Translation.new(backend)
      end

      def teardown
        redis = Redis.new
        redis.flushdb
      end

      def test_get_all_nils
        result = @translation.get(nil, nil)
        assert(!result)
      end

      def test_exists?
        assert(!@translation.exists?(LOCALE_EN, KEY))
      end

      def test_non_existant_key
        assert(!@translation.exists?(LOCALE_EN, KEY))
        result = @translation.get(LOCALE_EN, KEY)
        assert_equal(KEY, result)
      end

      def test_put_and_get
        assert(!@translation.exists?(LOCALE_EN, KEY))
        @translation.put(LOCALE_EN, KEY, VAL)
        assert(@translation.exists?(LOCALE_EN, KEY))
        assert_equal(VAL, @translation.get(LOCALE_EN, KEY))
      end

      def test_18n
        val_en = 'read a book'
        val_es = 'leer un libro'
        @translation.put(LOCALE_EN, KEY, val_en)
        @translation.put(LOCALE_ES, KEY, val_es)
        assert_equal(val_en, @translation.get(LOCALE_EN, KEY))
        assert_equal(val_es, @translation.get(LOCALE_ES, KEY))
      end

      def test_simple_backend
        @backend = I18n::Backend::Simple.new
        @translation = Harbor::Contrib::Translations::Translation.new(backend)

        assert(!@translation.exists?(LOCALE_EN, KEY))
        @translation.put(LOCALE_EN, KEY, VAL)
        assert(@translation.exists?(LOCALE_EN, KEY))
        assert_equal(VAL, @translation.get(LOCALE_EN, KEY))
      end

      def test_redis_and_simple_backends
        redis = Redis.new
        redis.flushdb
        be1 = I18n::Backend::KeyValue.new(redis)
        be2 = I18n::Backend::Simple.new
        @translation = Harbor::Contrib::Translations::Translation.new(be1, be2)

        assert(!@translation.exists?(LOCALE_EN, KEY))
        assert(!@translation.exists_in_backend?(be1, LOCALE_EN, KEY))
        assert(!@translation.exists_in_backend?(be2, LOCALE_EN, KEY))

        @translation.put(LOCALE_EN, KEY, VAL)

        assert(@translation.exists?(LOCALE_EN, KEY))
        assert(@translation.exists_in_backend?(be1, LOCALE_EN, KEY))
        assert(!@translation.exists_in_backend?(be2, LOCALE_EN, KEY))
        assert_equal(VAL, @translation.get(LOCALE_EN, KEY))
        assert(@translation.exists_in_backend?(be2, LOCALE_EN, KEY))
      end

      def test_passthrough_gets
        redis = Redis.new
        redis.flushdb
        be1 = I18n::Backend::KeyValue.new(redis)
        be2 = I18n::Backend::Simple.new
        be2.store_translations(LOCALE_EN, {KEY, VAL}, :ecape => false)
        @translation = Harbor::Contrib::Translations::Translation.new(be1, be2)

        assert(!@translation.exists_in_backend?(be1, LOCALE_EN, KEY))
        assert(@translation.exists_in_backend?(be2, LOCALE_EN, KEY))

        @translation.get(LOCALE_EN, KEY)

        assert(@translation.exists_in_backend?(be1, LOCALE_EN, KEY))
        assert(@translation.exists_in_backend?(be2, LOCALE_EN, KEY))
      end

      def test_add_backend
        size = @translation.backends.size
        @translation.add_backend(nil)
        assert_equal(size, @translation.backends.size)

        be = I18n::Backend::Simple.new
        @translation.add_backend(be)
        assert_equal(size + 1, @translation.backends.size)
      end

    end
  end
end

