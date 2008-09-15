class Hello
  attr_accessor :view, :layout, :response
  def initialize(request, response)
    @response = response
    # We initialize a view object with the path to search
    # for views in, and with the object to bind to.
    @view = View.new(Pathname(__FILE__).dirname.parent + "views")

    # This is just an example. We'd only have to do this for
    # controllers who could have their layout overridden.
    @layout = "layouts/application.html.erb"
  end

  def world
    # We register our partials
    @view.register(:content, "hello/world.html.erb")
    @view.register(:form, "hello/_form.html.erb")

    # And then we call render, which is our kicker method, and take
    # the primary file to render.
    response.puts @view.render(layout)
  end

  def usa
    # For an action which doesn't use a layout
    response.puts @view.render("hello/usa.html.erb")
  end
end