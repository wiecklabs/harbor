require "dm-core"
require "dm-timestamps"
#require "dm-migrations"

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

        def self.load_session(delegate, cookie, request = nil)
          session = if expire_after = Harbor::Session.options[:expire_after]
            ::Session.first(:id => cookie, :updated_at.gte => Time.now - expire_after)
          else
            ::Session.get(cookie)
          end

          unless session
            session = ::Session.create
            delegate.session_created(session.id, request.remote_ip, request.env["HTTP_USER_AGENT"])
          end

          SessionHash.new(session)
        end

        def self.commit_session(data, request)
          record = data.instance
          record.update_attributes(:data => data.to_hash)
          record.id
        end
      end
    end

    class ::Session #:nodoc:
      include DataMapper::Resource
      
      property :id, String, :key => true, :default => lambda { `uuidgen`.chomp }
      property :data, DataMapper::Property::Object, :default => lambda { {} }
      property :created_at, DateTime
      property :updated_at, DateTime
    end
  end
end
