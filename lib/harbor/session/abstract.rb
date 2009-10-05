module Harbor
  class Session

    ##
    # Defines the API and default behavior for session stores. See Cookie, and
    # contrib/session/data_mapper for examples of usage.
    ##
    class Abstract
      ##
      # Receives the raw cookie data, and should return a hash
      # of the data for the session.
      ##
      def self.load_session(cookie)
        Marshal.load(cookie.unpack("m*")[0]) rescue {}
      end

      ##
      # Receives the session data hash, and should return the data
      # to be set for the cookie's value
      ##
      def self.commit_session(data)
        [Marshal.dump(data)].pack("m*")
      end
    end

  end
end