class Harbor
  class Autoloader
    def paths
      @paths ||= AutoloaderPaths.new
    end

    module ConstMissingLoader
      class << self
        def load(context, constant)
          if app = app_for(context)
            return load_app_constant(app, context, constant)
          elsif const = load_constant_from_known_paths(context, constant)
            return const
          end
        end

        private

        INVALID_APP_SUFFIXES = %W( lib env assets log public views )

        ##
        # Tries to find constants under known apps lib / models folders or
        # registered paths that are not under registered apps namespace.
        ##
        def load_constant_from_known_paths(context, constant)
          suffix = suffix_for(context, constant)

          application_paths = Harbor.registered_applications.map(&:root).map(&:to_s).join(',')
          registered_paths  = config.autoloader.paths.map(&:to_s).join(',')

          known_paths = "{{{#{application_paths}}/{lib,models}},{#{registered_paths}}}"

          if file = Dir["#{known_paths}/#{suffix}.rb"].first
            require file
            return context.const_get constant if context.const_defined? constant
          end

          module_candidate = Dir["#{known_paths}/#{suffix}/"].first
          if module_candidate && autoloadable_module?(module_candidate)
            return context.const_set constant, Module.new
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

          elsif !INVALID_APP_SUFFIXES.include?(suffix) && autoloadable_module?(app.root + suffix)
            return context.const_set constant, Module.new
          end
        end

        def autoloadable_module?(path)
          ::Dir.exist?(path) && !Dir["#{path}/**/*.rb"].empty?
        end

        def app_suffix(app, context, constant)
          suffix_for(context, constant, app.name)
        end

        def suffix_for(context, constant, root = 'Object')
          "#{context.name}::#{constant}".
            gsub(/#{root}(::)?/, '').
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

        def app_for(context)
          nesting = context.name.split('::')
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
        ConstMissingLoader.load(self, constant) or
          raise NameError, "uninitialized constant #{name == 'Object' ? '' : (name + "::")}#{constant}",
              caller.reject { |l| l =~ /^#{__FILE__}/ }
      end
    end

    private

    class AutoloaderPaths
      extend Forwardable
      def_delegators :@paths, :each, :map, :clear

      def initialize
        @paths = []
      end

      def <<(path)
        @paths << ::File.expand_path(path)
        @paths.uniq!
        self
      end
    end
  end
end

Module.class_eval { include Harbor::Autoloader::ModuleConstMissing }
