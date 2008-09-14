class Cluster
  attr_accessor :applications
  def initialize(*applications)
    @applications = applications
  end

  def call(env)
    applications.each do |application|
      response = application.call(env)
      return response if response[0] != 404
    end
    message = "The page you requested could not be found"
    [404, { "Content-Type" => "text/plain", "Content-Length" => message.size.to_s }, message.to_a]
  end
end