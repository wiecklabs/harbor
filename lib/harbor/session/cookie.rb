class Harbor
  class Session

    ##
    # Basic enhancement to Abstract session to automatically generate
    # session_id's.
    ##
    class Cookie < Abstract
      def self.load_session(delegate, cookie, request = nil)
        cookie = super
        
        unless cookie[:session_id]
          cookie[:session_id] = java.util.UUID.randomUUID.to_s
          delegate.session_created(cookie[:session_id], request.remote_ip, request.env["HTTP_USER_AGENT"])
        end
        
        cookie
      end
    end

  end
end