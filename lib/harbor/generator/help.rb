module Harbor
  class Generator

    class HelpCommand
      Harbor::Generator.register('harbor', 'help', self)

      def initialize(options)
        @command = options.first
      end

      def run
        if @command
          generator = Harbor::Generator.generators["harbor:#{@command}"]

          if !generator
            puts "Command '#{@command}' does not exist."
          else
            if generator.help.empty?
              puts "No help available for '#{@command}'."
            else
              puts generator.help
            end
          end

          exit(1)
        else
          puts Harbor::Generator.usage('harbor')
          exit(1)
        end
      end
    end

  end
end