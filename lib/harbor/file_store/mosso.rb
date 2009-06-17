require "vendor/cloudfiles-1.3.0/cloudfiles"

module Harbor
  class FileStore
    class Mosso < Harbor::FileStore

      attr_accessor :container

      def initialize(username, api_key, container_name, options = {})
        @username = username
        @api_key = api_key
        @container_name = container_name
        @options = options
      end

      def get(path)
        Harbor::FileStore::File.new(self, path)
      end

      def put(filename, file)
        url = container.connection.storagehost + container.connection.storagepath + "/#{container.name}/#{filename}"
        token = container.connection.authtoken

        path = nil

        if file.is_a?(::File)
          path = file.path
        elsif file.is_a?(Harbor::FileStore::File) && file.store.local?
          path = file.store.path + file.path
        end

        command = <<-CMD
        curl -X "PUT" \\
             -T #{path ? Shellwords.escape(path) : "-"} \\
             -H "X-Auth-Token: #{token}" \\
             -H "Content-Type: text/plain" \\
             https://#{url}
        CMD

        if path
          system(command)
        else
          IO::popen(command, "w") do |session|
            case file
            when ::File
              while data = file.read(500_000)
                session.write(data)
              end
            when Harbor::FileStore::File
              file.read do |block|
                session.write(block)
              end
            end
          end
        end
      end

      def delete(filename)
        container.delete_object(filename)
      end

      def exists?(filename)
        container.object_exists?(filename)
      end

      def open(filename, mode = "r", &block)
        url = container.connection.storagehost + container.connection.storagepath + "/#{container.name}/#{filename}"
        token = container.connection.authtoken

        command = <<-CMD
        curl -s -X "GET" \\
             -D - \\
             -H "X-Auth-Token: #{token}" \\
             https://#{url}
        CMD

        stream = IO::popen(command)

        headers = []

        while line = stream.gets
          break if line == "\r\n"
          headers << line
        end

        stream
        # 
        # object = container.object(filename)
        # 
        # # Hack: Mosso's cloudfiles library doesn't return objects
        # # which expose IO functionality, so we return our own.
        # Stream.new(object)
      end

      def size(filename)
        container.object(filename).bytes
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