require "dm-core"
require "dm-timestamps"

module Harbor
  module Contrib
    class Session
      ##
      # This is a database backed session handle for DataMapper. You can use it
      # instead of the builtin Harbor::Session::Cookie by doing:
      # 
      #   Harbor::Session.configure do |session|
      #     session[:store] = Harbor::Contrib::Session::DataMapper
      #   end
      # 
      # A basic Session resource is defined for you.
      ##
      class DataMapper < Harbor::Session::Abstract

        class SessionHash < Hash
          def initialize(instance)
            super()
            @instance = instance
            merge!(@instance.data)
          end

          def [](key)
            key == :session_id ? @instance.id : super
          end

          def []=(key, value)
            raise ArgumentError.new("You cannot manually set the session_id for a session.") if key == :session_id

            super
          end

          def to_hash
            {}.merge(reject { |key,| key == :session_id })
          end

          def instance
            @instance
          end
        end

        def self.load_session(cookie)
          session = if expire_after = Harbor::Session.options[:expire_after]
            ::Session.first(:id => cookie, :created_at.gte => Time.now - expire_after)
          else
            ::Session.get(cookie)
          end

          session ||= ::Session.create

          SessionHash.new(session)
        end

        def self.commit_session(data, request)
          record = data.instance
          record.update_attributes(:data => data.to_hash)
          unless record.user_agent
            agent = ::UserAgent.create(
              :remote_ip => request.remote_ip,
              :raw => request.env["HTTP_USER_AGENT"],
              :session => record
            )
          end
          record.id
        end
      end
    end

    class ::Session #:nodoc:
      include DataMapper::Resource
      
      has 1, :user_agent
      
      property :id, String, :key => true, :default => lambda { `uuidgen`.chomp }
      property :data, Object, :default => {}
      property :created_at, DateTime
      property :updated_at, DateTime
    end
    
    class ::UserAgent
      include DataMapper::Resource
      
      belongs_to :session
      
      property :id, String, :key => true, :default => lambda { `uuidgen`.chomp }
      property :remote_ip, Integer, :size => 8, :auto_validation => false
      property :session_id, String
      property :browser, String
      property :version, String
      property :raw, String, :length => 255
      
      def remote_ip=(ip)
        # We split in case X-Forwarded-For is a list, and rescue any errors
        # by setting the IP to 0.0.0.0 (which we'll treat as 'unknown').
        ip_as_int = IPAddr.new(ip.split(/,/, 2).first).to_i rescue 0
        attribute_set(:remote_ip, ip_as_int)
      end

      def remote_ip
        IPAddr.new(attribute_get(:remote_ip), Socket::AF_INET).to_s
      end
      
    end
  end
end