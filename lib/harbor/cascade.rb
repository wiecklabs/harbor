module Harbor
  class Cascade

    def initialize(environment, services, application, *ports)
      unless services.is_a?(Harbor::Container)
        raise ArgumentError.new("Harbor::Cascade#initialize[services] must be a Harbor::Container")
      end

      @services = services
      @applications = []
      @public_paths = []

      begin
        @applications << application.new(services, environment)
      rescue ArgumentError => e
        raise ArgumentError.new("#{application}: #{e.message}")
      end

      @public_paths << Pathname(application.public_path) if application.respond_to?(:public_path)

      ports.each do |port|
        begin
          @applications << port.new(services, environment)
        rescue ArgumentError => e
          raise ArgumentError.new("#{port}: #{e.message}")
        end

        @public_paths << Pathname(port.public_path) if port.respond_to?(:public_path)
      end

      @public_paths << Pathname("public")
    end

    def call(env)
      request = Request.new(self, env)
      response = Response.new(request)

      catch(:abort_request) do
        if file = find_public_file(request.path_info[1..-1])
          response.cache(nil, ::File.mtime(file), 86400) do
            response.stream_file(file)
          end
          return response.to_a
        end

        application, handler = nil

        @applications.each do |application|
          break if handler = application.router.match(request)
        end

        application = @applications.first unless handler
        request.application = application

        application.dispatch_request(handler, request, response)
      end

      response.to_a
    end

    def find_public_file(file)
      result = nil

      @public_paths.each do |public_path|
        if (path = public_path + file).file?
          result = path
          break
        end
      end

      result
    end

  end
end