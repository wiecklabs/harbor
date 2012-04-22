class Harbor
  class Autoloader
    INVALID_APP_SUFFIXES = %W( lib env assets log public views )

    def paths
      @paths ||= AutoloaderPaths.new
    end

    module ConstMissingLoader
      class << self
        def load(context, constant)
          if app = app_for(context)
            return load_app_constant(app, context, constant)
          elsif const = load_app_lib_or_model_root_constant(context, constant)
            return const
          elsif const = load_constant_from_registered_paths(context, constant)
            return const
          end

          nil
        end

        private

        def load_constant_from_registered_paths(context, constant)
          suffix = suffix_for(context, constant)

          paths = config.autoloader.paths.map(&:to_s).join(',')

          if file = Dir["{#{paths}}/#{suffix}.rb"].first
            require file
            return context.const_get constant if context.const_defined? constant
          end

          module_candidate = Dir["{#{paths}}/#{suffix}/"].first
          if module_candidate && autoloadable_module?(module_candidate)
            mod = Module.new
            context.const_set constant, mod
            return mod
          end
        end

        def load_app_lib_or_model_root_constant(context, constant)
          suffix = suffix_for(context, constant)

          paths = Harbor.registered_applications.map(&:root).map(&:to_s).join(',')

          if file = Dir["{#{paths}}/{lib,models}/#{suffix}.rb"].first
            require file
            return context.const_get constant if context.const_defined? constant
          end

          module_candidate = Dir["{#{paths}}/{lib,models}/#{suffix}/"].first
          if module_candidate && autoloadable_module?(module_candidate)
            mod = Module.new
            context.const_set constant, mod
            return mod
          end
        end

        def load_app_constant(app, context, constant)
          suffix = app_suffix(app, context, constant)

          if suffix.include?('/') && ::File.exist?(app.root + "#{suffix}.rb")
            require app.root + suffix
            return context.const_get constant if context.const_defined? constant
          elsif file = Dir["#{app.root}/{lib,models}/#{suffix}.rb"].first
            require file
            return context.const_get constant if context.const_defined? constant
          elsif autoloadable_module?(app.root + suffix)
            return if Autoloader::INVALID_APP_SUFFIXES.include? suffix

            mod = Module.new
            return context.const_set constant, mod
          end

          return
        end

        def autoloadable_module?(path)
          ::Dir.exist?(path) && !Dir["{#{path}/**/*.rb}"].empty?
        end

        def app_suffix(app, context, constant)
          "#{context.name}::#{constant}".
            gsub(/#{app.name}(::)?/, '').
            gsub('::', '/').
            underscore
        end

        def suffix_for(context, constant)
          "#{context.name}::#{constant}".
            gsub(/Object(::)?/, '').
            gsub('::', '/').
            underscore
        end

        def constantize(camel_cased_word)
          names = camel_cased_word.split('::')
          names.shift if names.empty? || names.first.empty?

          names.inject(Object) do |constant, name|
            constant.const_get(name, false)
          end
        end

        ##
        # Checks if const_missing is being called from an application namespace
        ##
        def app_for(context)
          # use #name instead of #to_s ?
          nesting = context.to_s.split('::')
          return if nesting.empty?

          if Harbor::registered_applications.include?(app = constantize(nesting.first))
            app
          end
        end
      end
    end

    module ModuleConstMissing
      # Steals append_features and exclude_from from ActiveSupport::Dependencies
      def self.append_features(base)
        base.class_eval do
          # Emulate #exclude via an ivar
          return if defined?(@_const_missing) && @_const_missing
          @_const_missing = instance_method(:const_missing)
          remove_method(:const_missing)
        end
        super
      end

      def self.exclude_from(base)
        base.class_eval do
          define_method :const_missing, @_const_missing
          @_const_missing = nil
        end
      end

      def const_missing(constant)
        # Make this an object
        ConstMissingLoader.load(self, constant) or
          raise NameError, "uninitialized constant #{name == 'Object' ? '' : (name + "::")}#{constant}",
              caller.reject { |l| l =~ /^#{__FILE__}/ }
      end
    end

    private

    class AutoloaderPaths
      def initialize
        @paths = []
      end

      def <<(path)
        @paths << ::File.expand_path(path)
        @paths.uniq!
        self
      end

      def each(&block)
        @paths.each &block
      end

      def map(&block)
        @paths.map &block
      end
    end
  end
end

Module.class_eval { include Harbor::Autoloader::ModuleConstMissing }
