class Wheels::Cascade < Wheels::Application

  ##
  # We merge the routes for additional applications into the primary router
  # using the primary application's spoke.
  ##
  def initialize(application, *spokes)
    @applications = [application, *spokes]

    @services = application.services
    routes = application.routes

    spokes.each { |spoke| routes.merge!(spoke.routes(@services)) }

    super(routes)
  end

  def find_public_file(file)
    @applications.each do |application|
      next unless application.respond_to?(:public_path)

      path = Pathname(application.public_path) + file
      return path if path.exist?
    end

    path = Pathname("public") + file
    path.exist? ? path : nil
  end

end