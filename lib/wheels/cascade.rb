module Wheels
  class Cascade < Wheels::Application

    ##
    # We merge the routes for additional applications into the primary router
    # using the primary application's spoke.
    ##
    def initialize(application, *spokes)
      @applications = [application, *spokes]

      self.class.services = application.services
      routes = application.routes

      @public_paths = []
      @public_paths << Pathname(application.public_path) if application.respond_to?(:public_path)

      spokes.each do |spoke|
        routes.merge!(spoke.routes(self.class.services))
        @public_paths << Pathname(spoke.public_path) if spoke.respond_to?(:public_path)
      end

      @public_paths << Pathname("public")

      super(routes)
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