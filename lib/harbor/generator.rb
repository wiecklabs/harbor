require 'pathname'
require 'erubis'

module Harbor

  module Generator

    class GeneratorError < StandardError; end
    class UnknownCommandError < GeneratorError; end
    class GeneratorArgumentError < GeneratorError; end

    def self.run(app, command, options = [])
      executor = if klass = @@generators["#{app}:#{command}"]
        klass.new(options)
      else
        raise UnknownCommandError.new("Unknown Command: #{command}")
      end

      executor.run
    end

    @@generators = {}
    def self.register(app, command, klass)
      @@generators["#{app}:#{command}"] = klass
    end

    class SetupCommand
      APP = 'harbor'
      COMMAND = 'setup'
      Harbor::Generator.register(APP, COMMAND, self)

      attr_reader :app_name

      def initialize(options)
        @app_name = options.first

        raise GeneratorArgumentError.new("#{COMMAND} requires only an application name.") unless @app_name
      end

      def run
        skeleton_path = Pathname(__FILE__) + '../generator/skeletons/basic/*'

        `mkdir #{@app_name}`
        `cp -rp #{skeleton_path} #{@app_name}`

        # Evaluate all of the skeleton templates
        Dir["#{@app_name}/**/*.skel"].each do |path|
          ::File.open(path.sub('.skel', ''), 'w') do |file|
            file.puts Erubis::FastEruby.new(::File.read(path), :pattern => '##> <##').evaluate(self)
          end

          FileUtils.rm(path)
        end

        `mv #{@app_name}/lib/appname.rb  #{@app_name}/lib/#{@app_name}.rb`
        `mv #{@app_name}/lib/appname  #{@app_name}/lib/#{@app_name}`
      end

      def app_class
        # 'sample' => 'Sample'
        # 'cool_app' => 'CoolApp'
        @app_name.gsub(/(^|-|_)[a-z0-9]{1}/) { |m| m.sub(/-|_/, '').upcase }
      end

    end

  end

end