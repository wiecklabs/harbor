module Harbor

  def self.translation_engine
    @translation_engine
  end

  def self.translation_engine=(value)
    @translation_engine = value
  end

end

module Harbor

  module I18N

    class Translation

      attr_reader :culture_code, :original, :translation

      def initialize(culture_code, original, translation)
        @culture_code = culture_code
        @original = original
        @translation = translation
      end

    end

    class TranslationStore

      def translate(culture_code, key, substitiutions = nil)
        translation = get(culture_code, key)

        if translation.nil? || translation.translation.nil?
          logger.warn "Got #{translation.inspect} when translating key:'#{key}' into #{culture_code} with substitiutions: #{substitiutions.inspect}"

          substitute(key, substitiutions)
        else
          substitute(translation.translation, substitiutions)
        end
      end

      protected

      def logger
        Logging::Logger[self.class]
      end

      SUBSTITUTION_PATTERN = /%\{(\w+)\}/

      def substitute(text, substitiutions)
        return text if substitiutions.blank?

        text.gsub(SUBSTITUTION_PATTERN) do |match|
          substitiutions[$1.to_sym]
        end

      end

    end

    class MemoryTranslationStore < TranslationStore

      def initialize
        clear
      end

      def clear
        @store = Hash.new do |h, k|
          h[k] = {}
        end
      end

      def get(culture_code, key, auto_create = true)
        if translation = @store[culture_code][key]
          translation
        elsif auto_create
          Harbor::Locale.active_locales.each do |l|
            put(l.culture_code, key, key, false)
          end

          get(culture_code, key, false)
        end
      end

      def put(culture_code, key, value, allow_overwrite = true)
        @store[culture_code][key] = Translation.new(culture_code, key, value) if (allow_overwrite || @store[culture_code][key].nil?)
      end

      def delete(culture_code, key)
        @store[culture_code].delete_if { |k, v| k == key }
      end

      def all(culture_code)
        @store[culture_code]
      end

    end

    class DataMapperModelTranslationStore < TranslationStore

      def initialize(model)
        @model = model
      end

      def clear
        @model.all.destroy
      end

      def get(culture_code, key, auto_create = true)
        if translation = @model.first(:culture_code => culture_code, :original => key)
          translation
        elsif auto_create
          Harbor::Locale.active_locales.each do |l|
            put(l.culture_code, key, key, false)
          end

          get(culture_code, key, false)
        end
      end

      def put(culture_code, key, value, allow_overwrite = true)
        translation = @model.first_or_create(:culture_code => culture_code, :original => key)
        if allow_overwrite || translation.translation.nil?
          translation.translation = value
          translation.save!
        end
      end

      def delete(culture_code, key)
        if translation = @model.first(:culture_code => culture_code, :original => key)
          translation.destroy
        end
      end

      def all(culture_code)
        @model.all(:culture_code => culture_code, :order => [:original.asc])
      end

    end

    class CascadingTranslationStore < TranslationStore

      def initialize(transient_store, persistent_store)
        @transient_store = transient_store
        @persistent_store = persistent_store
      end

      def clear
        @transient_store.clear
        sync_transient_store
      end

      def get(culture_code, key, auto_create = true)
        sync_transient_store unless @transient_store_synced

        if translation = @transient_store.get(culture_code, key, false)
          return translation
        end

        if translation = @persistent_store.get(culture_code, key, false)
          @transient_store.put(culture_code, key, translation.translation)
          return translation
        end

        if auto_create
          Harbor::Locale.active_locales.each do |l|
            put(l.culture_code, key, key, false)
          end
        end

        Translation.new(culture_code, key, key)
      end

      def put(culture_code, key, value, allow_overwrite = true)
        @transient_store.put(culture_code, key, value, allow_overwrite)

        Thread.new do
          @persistent_store.put(culture_code, key, value, allow_overwrite)
        end
      end

      def all(culture_code)
        @persistent_store.all(culture_code)
      end

      private

      def sync_transient_store
        Harbor::Locale.active_locales.each do |locale|
          @persistent_store.all(locale.culture_code).each do |key, translation|
            @transient_store.put(locale.culture_code, key, translation)
          end
        end

        @transient_store_synced = true
      end

    end

  end

end
