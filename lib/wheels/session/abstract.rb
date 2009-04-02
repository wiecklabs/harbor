module Wheels
  class Session

    ##
    # Defines the API and default behavior for session stores.
    # 
    # Adding a custom session store is trivial:
    # 
    #   class Wheels::DataMapper::Session < Abstract
    #     def self.load_session(cookie)
    #       session = ::Session.get(cookie.unpack("m*")[0])
    #       data = {}
    #       if session
    #         data[:session_id] = session.id
    #         data.merge!(session.data)
    #       else
    #         data[:session_id] = `uuidgen`.chomp
    #       end
    #       data
    #     end
    #     
    #     def commit_session(data)
    #       session = ::Session.first_or_create(:id => data[:session_id])
    #       session.update_attributes(:data => data.reject { |key,| key == :session_id })
    #       session.id
    #     end
    #   end
    #   
    #   Wheels::Session.configure do |session|
    #     session.store = Wheels::DataMapper::Session
    #   end
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