class Default < Application

  attr_accessor :mailer

  def index
    @response.render("default/index")
  end

end