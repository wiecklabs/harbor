class Default

  attr_accessor :request, :response, :mailer

  def index
    response.render "default/index"
  end

end