require "pathname"
require Pathname(__FILE__).dirname + "helper"
require "harbor/mailer"

class MailerTest < Test::Unit::TestCase

  def test_tokenize_urls_with_plain_text
    mailer = Harbor::Mailer.new
    url = "http://test.com"
    mailer.text = url
    mailer.tokenize_urls!("http://m.wieck.com/m/%s?r=%s")

    assert_equal("http://m.wieck.com/m/#{CGI.escape(mailer.envelope_id)}?r=#{CGI.escape([url].pack("m"))}", mailer.text)
  end

  def test_tokenize_urls_with_html
    mailer = Harbor::Mailer.new
    url = "http://test.com"
    mailer.html = "<a href=\"#{url}\">Link</a>"
    mailer.tokenize_urls!("http://m.wieck.com/m/%s?r=%s")

    assert_equal("<a href=\"http://m.wieck.com/m/#{CGI.escape(mailer.envelope_id)}?r=#{CGI.escape([url].pack("m"))}\">Link</a>", mailer.html)
  end

  def test_tokenize_urls_with_https
    mailer = Harbor::Mailer.new
    url = "https://test.com"
    mailer.text = url
    mailer.tokenize_urls!("http://m.wieck.com/m/%s?r=%s")

    assert_equal("http://m.wieck.com/m/#{CGI.escape(mailer.envelope_id)}?r=#{CGI.escape([url].pack("m"))}", mailer.text)
  end

  ##
  # Fixing an issue reported by Drew where links would be blown away.
  # 
  def test_tokenize_urls_with_link_as_name
    mailer = Harbor::Mailer.new
    destination_url = "http://test.com"

    mailer.html = "<a href=\"#{destination_url}\">#{destination_url}</a>"
    mailer.tokenize_urls!("http://m.wieck.com/m/%s?r=%s")

    url = "http://m.wieck.com/m/#{CGI.escape(mailer.envelope_id)}?r=#{CGI.escape([destination_url].pack("m"))}"
    assert_equal("<a href=\"#{url}\">#{destination_url}</a>", mailer.html)
  end

end