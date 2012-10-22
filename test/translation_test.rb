require "pathname"
require Pathname(__FILE__).dirname + "helper"
require "harbor/contrib/translations/translation_chain"

module Contrib
  module Translations

    class TranslationTest < Test::Unit::TestCase

      LOCALE_EN = 'en_us'
      LOCALE_ES = 'es_mx'
      KEY = 'subscribe'
      VAL = 'you should subscribe'

      attr_accessor :backend

      def setup
        redis = Redis.new
        backend = I18n::Backend::KeyValue.new(redis)
        @t = Harbor::Contrib::Translations::TranslationChain.new(backend)
      end

      def teardown
        redis = Redis.new
        redis.flushdb
      end

      def test_get_all_nils
        result = @t.get(nil, nil)
        assert(!result)
      end

      def test_exists?
        assert(!@t.exists?(LOCALE_EN, KEY))
      end

      def test_non_existant_key
        assert(!@t.exists?(LOCALE_EN, KEY))
        result = @t.get(LOCALE_EN, KEY)
        assert_equal(KEY, result)
      end

      def test_put_and_get
        assert(!@t.exists?(LOCALE_EN, KEY))
        @t.put(LOCALE_EN, KEY, VAL)
        assert(@t.exists?(LOCALE_EN, KEY))
        assert_equal(VAL, @t.get(LOCALE_EN, KEY))
      end

      def test_18n
        val_en = 'read a book'
        val_es = 'leer un libro'
        @t.put(LOCALE_EN, KEY, val_en)
        @t.put(LOCALE_ES, KEY, val_es)
        assert_equal(val_en, @t.get(LOCALE_EN, KEY))
        assert_equal(val_es, @t.get(LOCALE_ES, KEY))
      end

      def test_simple_backend
        @backend = I18n::Backend::Simple.new
        @t = Harbor::Contrib::Translations::TranslationChain.new(backend)

        assert(!@t.exists?(LOCALE_EN, KEY))
        @t.put(LOCALE_EN, KEY, VAL)
        assert(@t.exists?(LOCALE_EN, KEY))
        assert_equal(VAL, @t.get(LOCALE_EN, KEY))
      end

      def test_redis_and_simple_backends
        redis = Redis.new
        redis.flushdb
        be1 = I18n::Backend::KeyValue.new(redis)
        be2 = I18n::Backend::Simple.new
        @t = Harbor::Contrib::Translations::TranslationChain.new(be1, be2)

        assert(!@t.exists?(LOCALE_EN, KEY))
        assert(!@t.exists_in_backend?(be1, LOCALE_EN, KEY))
        assert(!@t.exists_in_backend?(be2, LOCALE_EN, KEY))

        @t.put(LOCALE_EN, KEY, VAL)

        assert(@t.exists?(LOCALE_EN, KEY))
        assert(@t.exists_in_backend?(be1, LOCALE_EN, KEY))
        assert(@t.exists_in_backend?(be2, LOCALE_EN, KEY))
        assert_equal(VAL, @t.get(LOCALE_EN, KEY))
      end

      def test_passthrough_gets
        redis = Redis.new
        redis.flushdb
        be1 = I18n::Backend::KeyValue.new(redis)
        be2 = I18n::Backend::Simple.new
        be2.store_translations(LOCALE_EN, {KEY => VAL}, :escape => false)
        @t = Harbor::Contrib::Translations::TranslationChain.new(be1, be2)

        assert(!@t.exists_in_backend?(be1, LOCALE_EN, KEY))
        assert(@t.exists_in_backend?(be2, LOCALE_EN, KEY))

        @t.get(LOCALE_EN, KEY)

        assert(@t.exists_in_backend?(be1, LOCALE_EN, KEY))
        assert(@t.exists_in_backend?(be2, LOCALE_EN, KEY))
      end

      def test_add_backend
        size = @t.backends.size
        @t.add_backend(nil)
        assert_equal(size, @t.backends.size)

        be = I18n::Backend::Simple.new
        @t.add_backend(be)
        assert_equal(size + 1, @t.backends.size)
      end

      def test_keys
        @t.put(LOCALE_EN, KEY, VAL)
        keys = @t.keys
        assert_equal(1, keys.size)
        assert_equal("#{LOCALE_EN}.#{KEY}", keys[0])
      end

    end
  end
end

