class Harbor
  ##
  # Really basic code reloader.
  #
  # When enabled, it will listen for incoming requests on dispatcher and will
  # reload changed files by simply removing them from $LOADED_FEATURES and
  # requiring them again, only controllers and helpers have "special treatment".
  #
  # Controllers will have their classes / constants removed when reloaded
  # so that we do not end up with filters being registerd multiple times and
  # new helpers will be included on Harbor::ViewContext.
  ##
  class Reloader
    attr_accessor :cooldown

    FILES = Hash.new do |hash, file|
      hash[file] = ReloadableFile.new(file)
    end

    def initialize(cooldown = 1)
      @cooldown   = cooldown
      @last       = (Time.now - cooldown)
    end

    def enable!
      @enabled = true
      Dispatcher::register_event_handler(:begin_request) do
        perform
      end
    end

    def enabled?
      @enabled
    end

    def populate_files
      Dir[*paths].each { |file| FILES[file] = ReloadableFile.new(file, false) }
    end

    def perform
      if @cooldown && Time.now > @last + @cooldown
        Thread.list.size > 1 ? Thread.exclusive { reload! } : reload!
        @last = Time.now
      end
    end

    def reload!
      with_reloadable_files do |file|
        if file.updated?
          if file.controller_file? && file.required?
            file.remove_constant
          end
          file.reload
        elsif file.new_file?
          file.reload
          file.register_helper if file.helper_file?
        end
      end
    end

    private

    def with_reloadable_files
      Dir[*paths].each do |file|
        yield FILES[file]
      end
    end

    def paths
      @paths ||=
        begin
          Harbor::registered_applications.map do |app|
            "#{app.root}/{controllers,models,helpers,forms}/**/*.rb"
          end
        end
    end

    class ReloadableFile
      attr_reader :path, :mtime

      def initialize(path, new_file = true)
        @path = ::File.expand_path(path)
        update
        @new_file = new_file
      end

      # TODO: Clean this up
      def remove_constant
        return unless controller_file?

        const_str = path.split('/').last.gsub('.rb', '').camelize
        constant = nil

        if app.const_defined?(:Controllers)
          constant = app::Controllers.const_get const_str if app::Controllers.const_defined? const_str
        end

        # Support for controllers defined at application root namespace instead
        # of controller modules
        unless constant
          constant = app.const_get const_str if app.const_defined? const_str
        end

        raise "Was not able to find controller constant for #{path}" unless constant

        puts "[DEBUG] undefining #{constant}" if ENV['DEBUG']
        names = constant.name.split('::')
        constant = names.pop

        mod = names.inject(Object) do |constant, name|
          constant.const_get(name, false)
        end

        mod.instance_eval { remove_const constant }
      end

      def controller_file?
        @controller_file ||=
          begin
            app && path =~ /^#{app.root}\/controllers\//
          end
      end

      def helper_file?
        @helper_file ||=
          begin
            app && path =~ /^#{app.root}\/helpers\//
          end
      end

      def new_file?
        @new_file
      end

      def register_helper
        return unless helper_file?

        helper = path.split('/').last.gsub('.rb', '').camelize
        config.helpers.register app::Helpers.const_get helper
      end

      def update
        @mtime = ::File.mtime(path)
        @new_file = false
      end

      def updated?
        !removed? && mtime != ::File.mtime(path)
      end

      def removed?
        !::File.exist?(@path)
      end

      def required?
        $LOADED_FEATURES.include? path
      end

      def reload
        puts "[DEBUG] reloading #{path}" if ENV['DEBUG']
        $LOADED_FEATURES.delete path
        require path
        update
      end

      def app
        @app ||= Harbor::registered_applications.find { |app| path =~ /^#{app.root}\// }
      end
    end
  end
end
