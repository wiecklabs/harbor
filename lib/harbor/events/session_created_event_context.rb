module Harbor
  module Events
    class SessionCreatedEventContext
      
      attr_reader :session_id, :remote_ip, :user_agent
      
      def initialize(session_id, remote_ip, user_agent)
        @session_id = session_id
        @remote_ip = remote_ip
        @user_agent = user_agent
      end
      
    end
  end
end
