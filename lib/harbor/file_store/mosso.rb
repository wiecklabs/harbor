require "vendor/cloudfiles-1.3.0/cloudfiles"

module Harbor
  class FileStore
    class Mosso < Harbor::FileStore

      class Stream
        def initialize(object)
          @object = object
        end

        def read(bytes = nil)
          return nil if bytes && @data
          @data = @object.data
        end
      end

      attr_accessor :container

      def initialize(username, api_key, container_name)
        @username = username
        @api_key = api_key
        @container_name = container_name
      end

      def put(filename, file)
        object = container.create_object(filename)
        object.write(file)
      end

      def delete(filename)
        container.delete_object(filename)
      end

      def exists?(filename)
        container.object_exists?(filename)
      end

      def open(filename, mode = "r", &block)
        object = container.object(filename)
        Stream.new(object)
      end

      def container
        @container ||= connect!
      end

      private

      def connect!
        @connection = CloudFiles::Connection.new(@username, @api_key, true)
        @container = @connection.container(@container_name)
      end

      def connected?
        @connection && @connection.authok?
      end

    end
  end
end