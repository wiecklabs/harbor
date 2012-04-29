class Harbor
  class Reloader
    attr_accessor :cooldown

    def initialize(cooldown = 1)
      @cooldown   = cooldown
      @last       = (Time.now - cooldown)
    end

    def enable!
      Dispatcher::register_event_handler(:begin_request) do
        perform
        load_watchers
      end
    end

    def perform
      if @cooldown && Time.now > @last + @cooldown
        Thread.list.size > 1 ? Thread.exclusive { reload! } : reload!
        @last = Time.now
      end
    end

    def reload!
      files_watched.each do |file|
        if watcher = WATCHERS[file]
          if watcher.updated?
            watcher.remove_constant if watcher.controller_file?
            watcher.reload
          end
        else # new file
          watcher = WATCHERS[file] = FileWatcher.new(file)
          watcher.reload
          watcher.register_helper if watcher.helper_file?
        end
      end
    end

    private

    WATCHERS = {}

    def load_watchers
      files_watched.each do |file|
        WATCHERS[file] = FileWatcher.new(file)
      end
    end

    def files_watched
      Dir[*paths]
    end

    def paths
      @paths ||=
        begin
          Harbor::registered_applications.map do |app|
            "#{app.root}/{controllers,models,helpers,forms}/**/*.rb"
          end
        end
    end

    class FileWatcher
      attr_reader :path, :mtime

      def initialize(path)
        @path = ::File.expand_path(path)
        update
      end

      def remove_constant
        return unless @app && controller_file?

        const_str = path.split('/').last.gsub('.rb', '').camelize
        constant = nil

        if @app.const_defined?(:Controllers)
          constant = @app::Controllers.const_get const_str if @app::Controllers.const_defined? const_str
        end

        unless constant
          constant = @app.const_get const_str if @app.const_defined? const_str
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
            @app = Harbor::registered_applications.find { |app| path =~ /^#{app.root}\/controllers\// }
            !!@app
          end
      end

      def helper_file?
        @helper_file ||=
          begin
            @app = Harbor::registered_applications.find { |app| path =~ /^#{app.root}\/helpers\// }
            !!@app
          end
      end

      def register_helper
        return unless @app && helper_file?

        helper = path.split('/').last.gsub('.rb', '').camelize
        config.helpers.register @app::Helpers.const_get helper
      end

      def update
        @mtime = ::File.mtime(path)
      end

      def updated?
        required? && !removed? && mtime != ::File.mtime(path)
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
      end
    end
  end
end
