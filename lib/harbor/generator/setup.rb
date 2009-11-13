require "fileutils"

module Harbor
  class Generator
    class SetupCommand
      HELP = <<-HELP
Usage: harbor setup app_name

Sets up a new Harbor port using the conventional directory
structure. The application can be booted using your server
of choice:

  > rackup                  # http://localhost:9292/
  > unicorn                 # http://localhost:8080/
  > thin -R config.ru start # http://localhost:3000/

HELP

      Harbor::Generator.register('harbor', 'setup', self, "Sets up a new harbor project.", HELP)

      attr_reader :app_name

      def initialize(options)
        @app_name = options.first

        unless @app_name
          puts HELP
          exit(1)
        end
      end

      def log(action, message)
        puts "%12s  %s" % [action, message]
      end

      def run
        unless File.exists?(@app_name)
          log("create", @app_name)
          `mkdir #{@app_name}`
        end

        skeleton_path = Pathname(__FILE__).dirname + 'skeletons/basic'
        Dir[skeleton_path + "**/*"].each do |item|
          item = Pathname(item)
          relative_path = "#{@app_name}/#{item.relative_path_from(skeleton_path)}"
          relative_path.sub!("appname", @app_name)

          if File.exists?(relative_path.sub(/\.skel$/, ""))
            log("exists", relative_path.sub(/\.skel$/, ""))
            next
          end

          if item.directory?
            log("create", relative_path)

            `mkdir #{relative_path}`
          elsif relative_path.sub!(/\.skel$/, "")
            log("create", relative_path)

            ::File.open(relative_path, 'w') do |file|
              file.puts Erubis::FastEruby.new(::File.read(item), :pattern => '##> <##').evaluate(self)
            end
          else
            log("create", relative_path)

            FileUtils.cp(item, relative_path)
          end
            
        end

        `chmod +x #{@app_name}/config.ru`
      end

      def app_class
        # 'sample' => 'Sample'
        # 'cool_app' => 'CoolApp'
        @app_name.gsub(/(^|-|_)[a-z0-9]{1}/) { |m| m.sub(/-|_/, '').upcase }
      end

    end
  end
end