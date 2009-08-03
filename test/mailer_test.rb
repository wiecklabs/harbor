require "pathname"
require Pathname(__FILE__).dirname + "helper"
require "harbor/mailer"

class MailerTest < Test::Unit::TestCase

  def test_env_setting_to_override_from
    mailer = Harbor::Mailer.new
    mailer.to = "jdoe@example.com"
    assert_match(/to: jdoe@example.com/i, mailer.to_s)

    ENV["WHEELS_MAILTO"] = "test@example.com"
    assert_no_match(/to: jdoe@example.com/i, mailer.to_s)
    assert_match(/to: test@example.com/i, mailer.to_s)
  end

  def test_tokenize_urls_with_plain_text
    mailer = Harbor::Mailer.new
    url = "http://test.com"
    mailer.text = url
    mailer.tokenize_urls!("http://m.wieck.com")

    assert_equal("http://m.wieck.com/m/#{mailer.envelope_id}?r=#{CGI.escape([url].pack("m"))}", mailer.text)
  end

  def test_tokenize_urls_with_html
    mailer = Harbor::Mailer.new
    url = "http://test.com"
    mailer.rawhtml = "<a href=\"#{url}\">Link</a>"
    mailer.tokenize_urls!("http://m.wieck.com")

    assert_equal("<a href=\"http://m.wieck.com/m/#{mailer.envelope_id}?r=#{CGI.escape([url].pack("m"))}\">Link</a>", mailer.html)
  end

  def test_tokenize_urls_with_https
    mailer = Harbor::Mailer.new
    url = "https://test.com"
    mailer.text = url
    mailer.tokenize_urls!("http://m.wieck.com")

    assert_equal("http://m.wieck.com/m/#{mailer.envelope_id}?r=#{CGI.escape([url].pack("m"))}", mailer.text)
  end

  ##
  # Fixing an issue reported by Drew where links would be blown away.
  # 
  def test_tokenize_urls_with_link_as_name
    mailer = Harbor::Mailer.new
    destination_url = "http://test.com"

    mailer.rawhtml = "<a href=\"#{destination_url}\">#{destination_url}</a>"
    mailer.tokenize_urls!("http://m.wieck.com")

    url = "http://m.wieck.com/m/#{mailer.envelope_id}?r=#{CGI.escape([destination_url].pack("m"))}"
    assert_equal("<a href=\"#{url}\">#{destination_url}</a>", mailer.html)
  end

  def test_lazy_attachments
    mailer_1 = Harbor::Mailer.new
    mailer_2 = Harbor::Mailer.new

    file = (Pathname(__FILE__).dirname + "helper.rb").to_s

    harbor_attachment = mailer_1.attach(file)
    mailer_2.attach_as(file, "helper.rb")

    assert_equal(mailer_1.attachments, mailer_2.attachments)

    mailfactory_attachment = mailer_1.mailfactory_add_attachment(file)

    assert_equal(mailfactory_attachment.to_s, harbor_attachment.to_s)
  end

end