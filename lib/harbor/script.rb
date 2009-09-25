require "harbor/logging"

gem "thin"
require 'thin/version'
require 'thin/daemonizing'

module Logging
  def log(message)
    Harbor::Script.logger << message + "\n"
  end
  module_function :log
end

module Harbor
  ##
  # Class for defining and running daemonizable scripts.
  # 
  #   services = Harbor::Container.new
  #   services.register("mailer", Harbor::Mailer)
  #   
  #   class Processor < Harbor::Script
  #   
  #     attr_accessor :mailer
  #   
  #     def self.pid_file
  #       "tmp/processor.pid"
  #     end
  #   
  #     def self.log_file
  #       "log/processor.log"
  #     end
  #   
  #     def self.run!
  #       loop do
  #         # processing code
  #       end
  #     end
  #   end
  #   
  #   Harbor::Script::Runner.new(ARGV, services, Processor).run!
  ##
  class Script
    include Thin::Daemonizable

    attr_accessor :options, :services

    def self.logger
      @logger ||= begin
        logger = Logging::Logger[self]
        logger.additive = false
        logger.level = :info
        logger.add_appenders(Logging::Appenders::Stdout.new)
        logger
      end
    end

    def logger
      self.class.logger
    end

    def self.pid_file
      raise NotImplementedError.new("#{self}#pid_file must be defined.")
    end

    def self.log_file
      raise NotImplementedError.new("#{self}#log_file must be defined.")
    end

    def initialize
      @on_restart = lambda do
        exec("#{$0} #{'--daemonize' if @options[:daemonize]} start")
      end

      @pid_file = self.class.pid_file
      @log_file = self.class.log_file
    end

    def log(message)
      if @options[:daemonize]
        self.class.logger << message + "\n"
      else
        puts message
      end
    end

    def name
      $0
    end

    def stop
      log ">> Stopping"
    end

    def run!
      raise NotImplementedError.new("#{self}.run! must be defined.")
    end

    class Runner

      COMMANDS = %w(start stop restart)

      def initialize(argv, services, script)
        raise ArgumentError.new("services must be a Harbor::Container but was #{services.inspect}") unless services.is_a?(Harbor::Container)

        @argv = argv
        @script = script
        @script_name = @script.to_s
        @services = services

        @services.register(@script_name, @script) unless services.registered?(@script_name)

        parse!
      end

      def parse!
        @options = {
          :daemonize => false
        }

        parser = OptionParser.new do |opts|
          opts.on("-d", "--daemonize", "Daemonize process") { @options[:daemonize] = true }
        end

        parser.parse!(@argv)
        @command = @argv.shift
      end

      def run!
        unless COMMANDS.include?(@command)
          puts "#{@command.inspect} is not a valid command. Commands are: #{COMMANDS.join(", ")}"
          exit 1
        end

        send(@command)
      end

      def start
        script = @services.get(@script_name, :options => @options, :services => @services)

        script.daemonize if @options[:daemonize]

        @argv.empty? ? script.run! : script.run!(*@argv)
      end

      def restart
        Harbor::Script.restart(@script.pid_file)
      end

      def stop
        Harbor::Script.kill(@script.pid_file)
      end
    end

  end
end