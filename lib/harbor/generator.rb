require 'pathname'
require 'erubis'

module Harbor

  class Generator

    class GeneratorError < StandardError; end
    class UnknownCommandError < GeneratorError; end
    class GeneratorArgumentError < GeneratorError; end

    attr_accessor :app, :command, :klass, :description, :help

    def initialize(app, command, klass, description, help)
      @app, @command, @klass, @description, @help = app, command, klass, description, help
    end

    def self.run(app, command, options = [])
      executor = if generator = @@generators["#{app}:#{command}"]
        generator.klass.new(options)
      else
        puts usage(app)

        exit(1)
      end

      executor.run
    end

    def self.usage(app)
      usage = []
      usage << "Usage #{app} command [options]"
      usage << ""
      usage << "Available commands:"

      @@generators.select { |key,| key =~ /^#{app}/ }.sort.each do |key, generator|
        usage << "%12s   %s" % [generator.command, generator.description]
      end

      usage
    end

    @@generators = {}
    def self.register(app, command, klass, description = "", help = "")
      @@generators["#{app}:#{command}"] = new(app, command, klass, description, help)
    end

    def self.generators
      @@generators
    end

    require Pathname(__FILE__).dirname + "generator/help"
    require Pathname(__FILE__).dirname + "generator/setup"
  end

end