require_relative 'session/abstract'
require_relative 'session/cookie'

module Harbor

  class Session
    include Harbor::Events

    DEFAULT_OPTIONS = {
      :key => "harbor.session",
      :domain => nil,
      :path => "/",
      :expire_after => nil,
      :store => Cookie
    }

    ##
    # Configures non-default session settings.
    #
    #   Harbor::Session.configure do |session|
    #     session[:domain] = "*.domain.com"
    #     session[:store] = Custom::Session::Store
    #   end
    ##
    def self.configure #:yields: default_options
      @options = DEFAULT_OPTIONS.dup
      yield(@options)
      @options
    end

    def self.options
      @options ||= DEFAULT_OPTIONS.dup
      @options
    end

    def initialize(request, key = nil)
      @options = self.class.options.dup
      @cookie = request.cookies[key] || request.cookies[@options[:key]]
      @store = self.class.options[:store]
      @request = request
      if @request.health_check? then
        @data ||= {}
      else
        @data ||= @store.load_session(self, @cookie, @request)
      end
    end

    def session_created(session_id, remote_ip, user_agent_raw)
      raise_event(:session_created, Harbor::Events::SessionCreatedEventContext.new(session_id, remote_ip, user_agent_raw)) unless @request.health_check?
    end

    def key
      @options[:key]
    end

    def []=(key, value)
      @data[key] = value
    end

    def [](key)
      @data[key]
    end

    def data
      @data
    end

    def id
      @data[:session_id]
    end

    def save
      cookie = {}
      cookie[:domain] = @options[:domain]
      cookie[:path] = @options[:path]
      cookie[:expires] = Time.now + @options[:expire_after] unless @options[:expire_after].nil?
      unless @request.health_check?
        cookie[:value] = @store.commit_session(@data, @request)
      end
      cookie
    end

    def destroy
      @data.clear
    end
  end
end
