module Wheels
  class Cascade

    def initialize(application, *spokes)
      @applications = []
      @public_paths = []
      @services = application.services

      @applications << application.new
      @public_paths << Pathname(application.public_path) if application.respond_to?(:public_path)

      spokes.each do |spoke|
        spoke.services = @services
        @applications << spoke.new

        @public_paths << Pathname(spoke.public_path) if spoke.respond_to?(:public_path)
      end

      @public_paths << Pathname("public")
    end

    def call(env)
      request = Request.new(self, env)
      response = Response.new(request)

      if file = find_public_file(request.path_info[1..-1])
        response.stream_file(file)
        return response.to_a
      end

      application, handler = nil

      @applications.each do |application|
        break if handler = application.router.match(request)
      end

      application = @applications.first unless handler
      request.application = application

      catch(:abort_request) do
        application.dispatch_request(handler, request, response)
      end

      response.to_a
    end

    def find_public_file(file)
      @public_paths.each do |public_path|
        path = public_path + file
        return path if path.file?
      end

      nil
    end

  end
end