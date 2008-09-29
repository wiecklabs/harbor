class Hello
  attr_accessor :view, :layout, :response
  def initialize(request, response)
    @response = response
  end

  def world
    response.render "hello/world.html.erb"
  end

  def usa
    response.render "hello/usa.html.erb", :form => View.new("hello/_form.html.erb"), :layout => nil
  end
end