module Wheels
  class Session

    ##
    # Basic enhancement to Abstract session to automatically generate
    # session_id's.
    ##
    class Cookie < Abstract
      def self.load_session(cookie)
        cookie = super
        cookie[:session_id] ||= `uuidgen`.chomp
        cookie
      end
    end

  end
end