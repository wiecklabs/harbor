rack = if RUBY_PLATFORM =~ /java/
  "jruby-rack"
else
  "rack"
end

begin
  require rack
rescue LoadError
  puts "   #{rack} gem is not available, please add it to you Gemfile and run bundle"
  exit(1)
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

module Harbor
  class Application

    def self.inherited(application)
      Harbor::register_application(application)
    end
    
  end
end
