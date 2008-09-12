class Users

  attr_reader :response

  def initialize(response)
    @response = response
  end

  def show(id)
    @user = User.get(id)
    response.render("show", binding)
  end

  def default_template_root
    Pathname.new(__FILE__).dirname
  end
end

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

get "/users/show/:id" do
  Users.new(Response.new(Application))).show(params[:id])
end