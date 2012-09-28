require "java"
require "rubygems"
require "bundler/setup" unless Object::const_defined?("Bundler")

require "singleton"

require "listen"

class Watcher
  include Singleton
  
  def initialize
    @interrupted = false
    
    # Hit Ctrl-C once to re-run all specs; twice to exit the program.
    Signal.trap("INT") do
      if @interrupted
        puts "\nShutting down..."
        exit
      else
        @interrupted = true
        run_all_specs
        @interrupted = false
      end
    end
  end
  
  def run
    # Output here just so you know when changes will be
    # picked up after you start the program.
    puts "Listening for changes..."
    listener.start
  end
  
  private
  def listener
    defaults = %w{ test lib controllers db env forms helpers models views }
    @listener ||= Listen.to(*defaults.select { |dir| Pathname(dir).exist? })
      .filter(/\.rb$/)
      .change do |modified, added, removed|
      modified.each do |path|
        relative_path_from_root = Pathname(path).relative_path_from(config.root)
        run_single_spec relative_path_from.to_s.sub(/(_spec)?\.rb/, "")
      end
    end
  end
  
  def run_single_spec(underscored_name)  
    spec = Pathname("test/#{underscored_name}_spec.rb")
    
    if spec.exist?
      puts "\n --- Running #{spec.basename('.rb')} ---\n\n"
      org.jruby.Ruby.newInstance.executeScript <<-RUBY, spec.to_s
        require "#{spec}"
        MiniTest::Unit.new._run
      RUBY
    else
      puts "No matching spec for #{spec}"
    end
  end

  def run_all_specs
    puts "\n --- Running all specs ---\n\n"
    org.jruby.Ruby.newInstance.executeScript <<-RUBY, "all-specs"
      Dir["test/**/*_spec.rb"].each { |file| require file }
      MiniTest::Unit.new._run
    RUBY
  end
end

Watcher::instance.run