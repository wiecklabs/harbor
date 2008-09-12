## config.ru

# An application is instance based. This means configuration
# is per-instance. Routes are per-instance. The framework
# is completely thread-safe.
app = Application.new

# Routes are explicit. No crazy route-helper API to learn.
app.route("/") do |request, response|
  response.puts "Hello World"
end

# There is no mechanism to instantiate your controllers for you.
# This can be added with a more generic handler. We're placing
# an emphasis on loose coupling at the expense of a few keystrokes.
app.route "/users/show/:id" do |request, response|
  Users.new(request, response).show(request.params["id"])
end

run app

# Sample external gem slice incorporation.
# Note, the "slice" is declarative, the "wiring"
# of including it in the +application+ is external so
# there's no coupling.
# Wieck::Authorization::routes.each do |matcher, handler|
#   app.route(matcher, &handler)
# end

Wieck::Authorization::Session.get(request.session_id)

## users.rb

# This is a Controller. It's just a plain old Ruby object that
# consumes a Request and a Response
class Users

  attr_reader :request, :response

  def initialize(request, response)
    @request = request
    @response = response
  end

  Wieck::Authorization::Session(:show, :update, :create, :destroy)

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

  def initialize
    @routes = Router.new
  end

  def call(env)
    # figure out what route we're at.
    response = Response.new
    request = Rake::Request.new(env)
    begin
      @routes.match(request).call(request, response)
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