require "pathname"
require "fileutils"
require "logger"
require "erubis"

module Harbor
  module Commands

    class Setup

      DEFAULT_LOGGER = Logger.new(STDOUT).tap do |logger|
        logger.formatter = ->(severity, time, progname, msg) { "%s %s\n" % [severity, msg] }
      end

      def initialize(app_name, root, logger = DEFAULT_LOGGER)
        @app_name = app_name
        @root = root
        @logger = logger
      end

      def log(action, message)
        @logger.info("%s %s" % [action, message]) if @logger
      end

      def run
        unless ::File.directory?(@root)
          log("create", @root)
          `mkdir #{@root}`
        end

        skeleton_path = Pathname(__FILE__).dirname + 'skeletons/default'

        Dir[skeleton_path + "**/*"].each do |item|
          next if ::File.basename(item) == ".gitkeep"

          item = Pathname(item)
          relative_path = ::File.join(@root, item.relative_path_from(skeleton_path))
          relative_path.sub!("appname", @app_name)

          if ::File.exists?(relative_path.sub(/\.skel$/, ""))
            log("exists", relative_path.sub(/\.skel$/, ""))
            next
          end

          if item.directory?
            log("create", relative_path)

            `mkdir #{relative_path}`
          elsif relative_path.sub!(/\.skel$/, "")
            log("create", relative_path)

            ::File.open(relative_path, 'w') do |file|
              file.puts Erubis::FastEruby.new(::File.read(item), :pattern => '<$= =$>').evaluate(self)
            end
          else
            log("create", relative_path)

            FileUtils.cp(item, relative_path)
          end

        end
      end

      # CamelCaseVersion of the supplied @app_name
      #
      #   'sample' => 'Sample'
      #   'cool_app' => 'CoolApp'
      def app_class
        @app_name.gsub(/(^|-|_)[a-z0-9]{1}/) { |m| m.sub(/-|_/, '').upcase }
      end

    end

  end
end