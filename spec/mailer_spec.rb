require "pathname"
require Pathname(__FILE__).dirname + "helper"

require "wheels/mailer"

class TestServer < Wheels::AbstractMailServer
  def send(mail)
    mail
  end
end

describe "Wheels::Mailer" do
  before :all do
    @server = TestServer.new
  end

  it "should pass itself to the server on send!" do
    mail = Wheels::Mailer.new(@server)
    mail.send!.should == mail
  end
end