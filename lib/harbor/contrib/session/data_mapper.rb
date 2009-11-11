require "dm-core"
require "dm-timestamps"

module Harbor
  module Contrib
    class Session
      ##
      # This is a database backed session handle for DataMapper. You can use it
      # instead of the builtin Harbor::Session::Cookie by doing:
      # 
      # Harbor::Session.configure do |session|
      #   session.store = Harbor::Contrib::Session::DataMapper
      # end
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

        def self.commit_session(data)
          record = data.instance
          record.update_attributes(:data => data.to_hash)
          record.id
        end
      end
    end

    class ::Session #:nodoc:
      include DataMapper::Resource

      property :id, String, :key => true, :default => lambda { `uuidgen`.chomp }
      property :data, Object, :default => {}
      property :created_at, DateTime
      property :updated_at, DateTime
    end
  end
end