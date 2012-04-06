require "pathname"
require "fileutils"
require "logger"
require "erubis"

class Harbor
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
          FileUtils.mkdir_p(@root)
        end

        skeleton_path = Pathname(__FILE__).dirname + 'skeletons/default'

        Dir[skeleton_path + "**/*"].each do |item|
          next if ::File.basename(item) == ".gitkeep"

          item = Pathname(item)
          relative_path = ::File.join(@root, item.relative_path_from(skeleton_path))
          relative_path.sub!("appname", @app_name)

          if ::File.exists?(relative_path)
            log("exists", relative_path)
            next
          end

          if item.directory?
            log("create", relative_path)

            FileUtils.mkdir_p(relative_path)
          elsif ::File.read(item)['<@']
            log("build", relative_path)

            ::File.open(relative_path, 'w') do |file|
              file.puts Erubis::Eruby.new(::File.read(item), :pattern => '<@ @>').evaluate(self)
            end
          else
            log("create", relative_path)

            FileUtils.cp(item, relative_path)
          end

        end
      end

      def app_name
        @app_name
      end

      # CamelCaseVersion of the supplied @app_name
      #
      #   'sample' => 'Sample'
      #   'cool_app' => 'CoolApp'
      def app_class
        @app_name.camelize
      end

    end

  end
end
