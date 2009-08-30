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
    def self.info(request, response, start_time, end_time)
      case
      when response.status >= 500 then status = "\033[0;31m#{response.status}\033[0m" # prints the status value in red
      when response.status >= 400 then status = "\033[0;33m#{response.status}\033[0m" # prints the status value in yellow
      else status = "\033[0;32m#{response.status}\033[0m"                             # prints the status value in green
      end

      message = "[#{self.class}] [#{start_time.strftime('%m-%d-%Y @ %H:%M:%S')}] [#{"%2.2fs" % (end_time - start_time)}] [#{request.remote_ip}] [#{request.request_method}] #{request.path_info} (#{status})"
      message << "\t #{request.params.inspect}" unless request.params.empty?
      message << "\n"

      if (request_logger = Logging::Logger["request"]).info?
        request_logger << message
      end
    end

    def self.error(exception, request, response, trace)
      Logging::Logger['error'] << trace
    end
  end
end

Harbor::Application.register_event(:request_complete) { |*args| Harbor::RequestLogger.info(*args) }
Harbor::Application.register_event(:exception) { |*args| Harbor::RequestLogger.error(*args) }