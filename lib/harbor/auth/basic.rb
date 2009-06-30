module Harbor
  module Auth
    ##
    # Simple mechanism for implementing HTTP basic authentication.
    # 
    #   get("/secret-page") do |request, response|
    #     Harbor::Auth::Basic.authenticate(request, response) { |username, password| username == "wieck" }
    # 
    #     response.puts "Secret Stuff"
    #   end
    ##
    class Basic

      AUTHORIZATION_KEYS = ['HTTP_AUTHORIZATION', 'X-HTTP_AUTHORIZATION', 'X_HTTP_AUTHORIZATION']

      attr_accessor :realm

      ##
      # Checks the credentials provided in the request against the provided
      # block. If the block returns false, the request aborted.
      ##
      def self.authenticate(request, response) #:yields: username, password
        auth = new(request)

        unless auth.provided? && yield(auth.credentials)
          response.headers["WWW-Authenticate"] = 'Basic realm="%s"' % auth.realm
          response.unauthorized!
        end
      end

      def initialize(request)
        @request = request
      end

      def provided?
        !!authorization_key
      end

      def credentials
        @request.env[authorization_key].split(' ', 2).last.unpack("m*").first.split(/:/, 2)
      end

      private

      def authorization_key
        @authorization_key ||= AUTHORIZATION_KEYS.detect { |key| @request.env.has_key?(key) }
      end

    end
  end
end