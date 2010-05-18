module Harbor

  class Daemon
    
    START_CONTEXT = {
      :argv => ARGV.map { |arg| arg.dup },
      :cwd => `/bin/sh -c pwd`.chomp("\n"),
      :cmd => $0.dup
    }

    DEFAULT_SLEEP_SECONDS = 60

    attr_accessor :logger
    attr_reader :worker, :options

    def initialize(worker, log_file, seconds_between_runs = DEFAULT_SLEEP_SECONDS)
      @worker = worker

      # The template may include the tag %PID to be replaced with
      # the PID of the forked worker process.  Don't use @log_file
      # directly, use self.log_file
      @log_file_template = log_file
      
      @seconds_between_runs = seconds_between_runs
    end
    
    def log_file
      @log_file ||= if @log_file_template.is_a?(::File)
        @log_file_template
      else
        @log_file_template.gsub('%PID', Process.pid.to_s)
      end
    end
    
    def detach
      srand
      fork and exit
      Process.setsid # detach -- we want to be able to close our shell!

      unless self.log_file.is_a?(::File)
        log_directory = ::File.dirname(self.log_file)
        ::File.mkdir_p(log_directory) unless ::File.directory?(log_directory)
      end

      redirect_io(@log_file)
    end
    
    def run
      @restart = false
      @alive = true
    
      # graceful restart
      trap(:HUP) do
        logger.info "Restarting gracefully." if logger
        @restart = true
        @alive = nil
        @worker.alive = nil
      end
    
      # graceful shutdown
      trap(:QUIT) do
        logger.info "Shutting down gracefully." if logger
        @alive = nil
        @worker.alive = nil
      end
    
      # quick exit
      [:TERM, :INT].each do |sig|
        trap(sig) do
          logger.info "Shutting down NOW" if logger
          cleanup!
    
          exit!(0)
        end
      end
      
      begin
        @worker.run
        sleep(@seconds_between_runs) if @alive
      end while @alive
        
      if @restart
        logger.info "Starting new daemon..."
        fork do
          Dir.chdir(START_CONTEXT[:cwd])
          exec(START_CONTEXT[:cmd], *START_CONTEXT[:argv])
        end
      end

      logger.info "Shutting down..." if logger
      cleanup!
    end
    
    def cleanup!
      worker.cleanup! if worker.respond_to?(:cleanup!)
    end

    private
    
    def redirect_io(file = nil)
      STDIN.reopen "/dev/null"
      STDOUT.reopen file || "/dev/null"
      STDOUT.sync = true

      STDERR.reopen STDOUT
      STDERR.sync = true
    end

  end

end