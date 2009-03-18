class Wheels::Cascade < Wheels::Application

  ##
  # We merge the routes for additional applications into the primary router
  # using the primary application's spoke.
  ##
  def initialize(application, *spokes)
    @services = application.services
    routes = application.routes

    spokes.each { |spoke| routes.merge!(spoke.routes(@services)) }

    super(routes)
  end

end