require Pathname(__FILE__).dirname + 'session/abstract'
require Pathname(__FILE__).dirname + 'session/cookie'

module Harbor

  class Session
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

    def initialize(request)
      @options = self.class.options.dup
      @cookie = request.cookies[@options[:key]]
      @store = self.class.options[:store]

      @data ||= @store.load_session(@cookie)
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

    def save
      cookie = {}
      cookie[:domain] = @options[:domain]
      cookie[:path] = @options[:path]
      cookie[:expires] = Time.now + @options[:expire_after] unless @options[:expire_after].nil?
      cookie[:value] = @store.commit_session(@data)
      cookie
    end

    def destroy
      @data.clear
    end
  end
end