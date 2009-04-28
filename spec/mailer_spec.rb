require "pathname"
require Pathname(__FILE__).dirname + "helper"

require "harbor/mailer"

class TestServer < Harbor::MailServers::Abstract
  def deliver(mail)
    mail
  end
end

describe "Harbor::Mailer" do
  before :all do
    @server = TestServer.new
  end

  it "should pass itself to the server on send!" do
    mail = Harbor::Mailer.new
    mail.mail_server = @server
    mail.send!.should == mail
  end

end