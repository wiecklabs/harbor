module Harbor
  class RequestLogger
    ##
    # Logs requests and their params the configured request logger.
    # 
    # Format:
    # 
    #   #application      #time                   #duration   #ip              #method #uri      #status   #params
    #   [PhotoManagement] [04-02-2009 @ 14:22:40] [0.12s]     [64.134.226.23] [GET]    /products (200)     {"order" => "desc"}
    ##
    def self.info(event)
      status = nil
      case
      when event.response.status >= 500 then status = "\033[0;31m#{event.response.status}\033[0m" # prints the status value in red
      when event.response.status >= 400 then status = "\033[0;33m#{event.response.status}\033[0m" # prints the status value in yellow
      else status = "\033[0;32m#{event.response.status}\033[0m"                             # prints the status value in green
      end

      message = "[#{self.class}] [#{event.start.strftime('%m-%d-%Y @ %H:%M:%S')}] [#{"%2.2fs" % (event.duration)}] [#{event.request.remote_ip}] [#{event.request.request_method}] #{event.request.path_info} (#{status})"
      message << "\t #{event.request.params.inspect}" unless event.request.params.empty?
      message << "\n"

      if (request_logger = Logging::Logger["request"]).info?
        request_logger.info { message }
      end
    end

    def self.error(event)
      Logging::Logger['error'].error { event.trace }
    end
  end
end

Harbor::Dispatcher.register_event_handler(:request_complete) { |event| Harbor::RequestLogger.info(event) }
Harbor::Dispatcher.register_event_handler(:exception) { |event| Harbor::RequestLogger.error(event) }
