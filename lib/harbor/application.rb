if RUBY_PLATFORM =~ /java/
  require "jruby-rack"
else
  require "rack"
end

require "yaml"

require_relative "events"
require_relative "request"
require_relative "response"
require_relative "block_io"
require_relative "events/dispatch_request_event"
require_relative "events/not_found_event"
require_relative "events/server_error_event"
require_relative "events/session_created_event_context"
require_relative "messages"

class Harbor
  class Application

    def self.inherited(application)
      Harbor::register_application(application)
    end

    def self.root
      @root
    end
  end
end
