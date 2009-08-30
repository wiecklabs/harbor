class Hello
  attr_accessor :request, :response

  def world
    response.render "hello/world.html.erb"
  end

  def usa
    response.render "hello/usa.html.erb", :form => Harbor::View.new("hello/_form.html.erb"), :layout => nil
  end
end