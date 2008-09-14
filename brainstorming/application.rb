## config.ru

# Instantiate a set of routes:
routes = Router.new

# Routes are explicit. No crazy route-helper API to learn.
routes.get("/") do |request, response|
  response.puts "Hello World"
end

# There is no mechanism to instantiate your controllers for you.
# This can be added with a more generic handler. We're placing
# an emphasis on loose coupling at the expense of a few keystrokes.
routes.get "/users/show/:id" do |request, response|
  Users.new(request, response).show(request.params["id"])
end

# Sample external gem slice incorporation.
# Note, the "slice" is declarative, the "wiring"
# of including it in the +application+ is external so
# there's no coupling.
#
#   Wieck::Authorization::routes.each do |matcher, handler|
#     routes.get(matcher, &handler)
#   end
#
# or:
#   routes.merge(Wieck::Authorization::routes)

run Application.new(routes)

## generic_handler.rb
# Example of what a GenericHandler would look like:
module GenericHandler
  
  def self.controllers
    @controllers ||= Hash.new { |h,k| h[k.to_s.downcase] = k }
  end
  
  def self.dispatch(request, response)
    controller = controllers[request.controller].new(request, response)
    if controller.class.public_methods.include?(request.params[:action])
      controller.send(request.params[:action])
    else
      raise Net::HTTP::NotAuthorized.new("This action is not available")
    end
  end
end

GenericHandler.controllers['users'] = User

routes.get "/:controller/:action/:id" do |request, response|
  GenericHandler.dispatch(request, response)
end

## users.rb

# This is a Controller. It's just a plain old Ruby object that
# consumes a Request and a Response
class Users
  
  attr_reader :request, :response
  
  def initialize(request, response)
    @request = request
    @response = response
  end
  
  include Extlib::Hook
  
  before :show do
    @session = Wieck::Authorization::Session.get(request.session_id)
  end
  
  after :show do
    @session.save! if @session
  end
  
  def show(id)
    @user = User.get(id)
    response.render("show", binding)
  end
  
  def update(id, user)
    @user = User.get(id)
    @user.attributes = user
    @user.save
    response.redirect("edit", @user.id)
  end
  
  def default_template_root
    Pathname.new(__FILE__).dirname
  end
end

## response.rb

# This is the Response object, a bit overly complex in this example, but
# basically just an IO object with a Status, Headers and a Buffer.
class Response < IO

  def initialize(application)
    @default_template_path = application.root / "app" / "views"
    super
  end
  
  def render(template_name, binding)
    @to_s = Erb.new(find_template(template_name, binding)).render(binding)
  end
  
  def to_s
    @to_s || render(nil)
  end
  
  private
  # This method is garbage right now. But basically it should return
  # the base template in a relative path to the controller (possibly in a gem),
  # or an overriden one, relative to the application.
  def find_template(template_name, default_template_root)
    overridden_path = @default_template_path / "#{template_name}.html.erb"
    if File.exists?(overridden_path)
      overridden_path
    else
      instance_eval(lambda { default_template_root }, binding) / "#{template_name}.html.erb"
    end
  end
end

## application.rb

# This is our Application / Dispatcher.
class Application
  
  def initialize(router)
    @routes = router
  end
  
  def call(env)
    # figure out what route we're at.
    response = Response.new
    request = Rake::Request.new(env)
    begin
      @routes.match(env).call(request, response)
    rescue
      if development?
        response.buffer.clear
        response.puts $!
        response.puts $!.backtrace
        response.puts request.to_yaml
      end
      response.status = 500
    end
    [response.status, response.headers, response.buffer]
  rescue
    [500, "", 0]
  end
  
  def route(matcher, &handler)
    @routes.register(matcher, &handler)
  end
end