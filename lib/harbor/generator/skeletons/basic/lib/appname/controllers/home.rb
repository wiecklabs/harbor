class Home

  attr_accessor :request, :response, :mailer

  def index
    response.render "home/index"
  end

end