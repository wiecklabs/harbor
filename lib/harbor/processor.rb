module Harbor
  class Processor

    include Harbor::Hooks

    def self.new(*args)
      raise "You must subclass Harbor::Processor and implement #reserve and #process" if self == Harbor::Processor
      raise "You must implement #{self}#reserve" unless instance_methods(false).include?("reserve")
      raise "You must implement #{self}#process" unless instance_methods(false).include?("process")

      processor = allocate

      processor.worker_count = 2
      processor.daemonize    = true
      processor.sleep_time   = 60
      processor.log_level    = :info
      processor.log_file     = "log/processor.log"

      processor.send(:initialize, *args)
      processor
    end

    ##
    # CONFUGURATION OPTIONS
    ##

    attr_accessor :worker_count
    attr_accessor :daemonize
    attr_accessor :sleep_time
    attr_accessor :log_level
    attr_accessor :log_file

    ##
    # Accepts an instance of OptionParser for wiring up options, like:
    # 
    #   processor = MyProcessor.new
    #   OptionParser.new do |opts|
    #     opts.banner = "Usage: my_processor [options]"
    #     processor.options(opts)
    #   end.parse!
    ##
    def options(optparse)
      optparse.on("-n", "--no-daemon", "Run in the foreground") { self.daemonize = false }
      optparse.on("-w", "--workers=COUNT", Integer, "Number of workers to spawn (default: #{worker_count})") { |count| self.worker_count = count }
      optparse.on("-l", "--log-level=LEVEL", [:debug, :info, :error], "Set log level (default: #{log_level})") { |log_level| self.log_level = log_level }
      optparse.on("-L", "--log-file=FILE", "Log file (default: #{log_file})") { |file| self.log_file = file }
      optparse.on("-s", "--sleep=SECONDS", Integer, "Sleep s seconds between runs (default: #{sleep_time})") { |sleep_time| self.sleep_time = sleep_time }
    end

    ##
    # This method must be over-ridden in your implementation of Harbor::Processor,
    # and should return a task to be performed inside of a forked worker process.
    # It should return nil when there are no available tasks.
    ##
    def reserve
      raise NotImplementedError.new("You must implement #{self.class}#reserve")
    end

    ##
    # This method must be over-ridden in your implementation of Harbor::Processor.
    # It will be called within the forked worker process, and accepts as its only
    # argument a task returned by #reserve.
    ##
    def process(task)
      raise NotImplementedError.new("You must implement #{self.class}#process(task)")
    end

    ##
    # This method can be over-ridden to define special behavior for when a task
    # is interrupted, such as updating a value in the database.
    ##
    def handle_interrupt(task)
    end

    ##
    # Method which can be over-ridden to define special behavior for unhandled exceptions,
    # such as marking a task as failed in the database.
    ##
    def handle_exception(task, exception)
      logger.error("#{exception}\n#{exception.backtrace.join("\n")}")
    end

    ##
    # Sometimes when running commands in a subshell (with backticks, system, etc.)
    # interrupts will be sent, but the process will exit silently. Processor#interruptible
    # swaps out the :INT handler to allow us to know when an action is interrupted,
    # and optionally rescue.
    ##
    def interruptible
      original_handler = trap(:INT, "DEFAULT")
      yield
    ensure
      trap(:INT, original_handler)
    end

    def start
      detach if daemonize

      logger.info "running at %s" % [Process.pid]
      logger.info "workers = #{worker_count}"

      trap_signals

      @workers = {}

      while alive?
        begin
          loop do
            break if worker_count == 0 && @workers.empty?

            (worker_count - @workers.size).times do
              unless task = reserve
                self.worker_count = 0
                break
              end

              @workers[spawn_worker(task)] = task
            end

            pid = Process.wait

            task = @workers.delete(pid)

            case $?.exitstatus
            when 0   # success
              logger.info "[worker#%-5s] %s: completed" % [Process.pid, task.inspect]
            when 1   # exception
              logger.info "[worker#%-5s] %s: failed" % [Process.pid, task.inspect]
            when 130 # interrupt
              logger.info "[worker#%-5s] %s: interrupted" % [Process.pid, task.inspect]
            end
          end
        rescue Errno::ECHILD
        end

        if alive?
          begin
            interruptible { sleep(sleep_time) }
          rescue Interrupt
            @alive = false
          end
        end
      end

      logger.info "shutting down"
    rescue => e
      logger.error("#{e}\n#{e.backtrace.join("\n")}")
    end

    def logger
      @logger ||= begin
        logger = Logging::Logger[self.class]
        logger.additive = false
        logger.level = log_level
        layout = Logging::Layouts::Pattern.new(:pattern => "%-5l %d: %m\n")

        if daemonize
          logger.add_appenders(Logging::Appenders::File.new(log_file, :layout => layout))
        else
          logger.add_appenders(Logging::Appenders::Stdout.new(:layout => layout))
        end
      end
    end

    private

    def alive?
      defined?(@alive) ? @alive : (@alive = true)
    end

    def spawn_worker(task)
      fork do
        begin
          $0 = "#{$0}[#{Time.now.strftime("%H:%M:%S")}] #{task.inspect}"
          srand
          ignore_signals

          process(task)
        rescue => e
          handle_exception(task, e)

          raise
        end
      end
    end

    def detach
      srand
      fork and exit
      Process.setsid # detach -- we want to be able to close our shell!

      log_directory = ::File.dirname(log_file)
      FileUtils.mkdir_p(log_directory) unless ::File.directory?(log_directory)

      redirect_io(log_file)
    end

    def redirect_io(file = nil)
      STDIN.reopen "/dev/null"
      STDOUT.reopen file || "/dev/null"
      STDOUT.sync = true

      STDERR.reopen STDOUT
      STDERR.sync = true
    end

    def trap_signals
      trap(:TTIN) do
        self.worker_count += 1
        logger.info "worker_count = #{worker_count}"
      end

      trap(:TTOU) do
        self.worker_count -= 1
        logger.info "worker_count = #{worker_count}"
      end

      graceful_shutdown = lambda do
        @alive = false
        self.worker_count = 0
        logger.info "gracefully shutting down."
      end

      trap(:QUIT, graceful_shutdown)
      trap(:TERM, graceful_shutdown)

      shutdown = lambda do
        @alive = false
        self.worker_count = 0
        logger.info "stopping workers and shutting down."
      end
      trap(:INT, shutdown)
    end

    def ignore_signals
      trap(:QUIT, "")
      trap(:TERM, "")
      trap(:TTIN, "")
      trap(:TTOU, "")
      trap(:INT, "")
    end

  end
end