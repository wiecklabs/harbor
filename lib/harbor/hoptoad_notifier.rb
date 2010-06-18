##
# Utility class for sending hoptoad notifications of exceptions in
# non-development environments.
# 
#   require 'harbor/hoptoad_notifier'
#   Harbor::HoptoadNotifier.hoptoad_api_key = "YOUR_API_KEY_HERE"
# 
#   Your API key can be found under Projects -> Project Name -> Edit this project -> Current API Key
##
require 'lilypad'

class Lilypad
  class <<self
    def production?
      Config.environments.include? ENV['ENVIRONMENT']
    end
  end
end

module Harbor
  class HoptoadNotifier
    def self.hoptoad_api_key=(api_key)
      @@api_key = api_key
    end

    def self.hoptoad_api_key
      @@api_key
    rescue NameError
      raise "Harbor::HoptoadNotifier.api_key not set."  
    end

    def self.hoptoad_api_key?
      defined?(@@api_key)
    end

    def self.notify(exception, request, response, trace)
      Lilypad.config self.hoptoad_api_key do
        environments(%w(production stage staging))
      end

      Lilypad.notify(exception, request.env)
    end
  end
end

Harbor::Application.register_event_handler(:exception) { |event| Harbor::HoptoadNotifier.notify(event.exception, event.request, event.response, event.trace) }
