require "helper"
require "wheels/mailer"

class MailerTest < Test::Unit::TestCase

  def test_tokenize_urls_with_plain_text
    mailer = Wheels::Mailer.new
    url = "http://test.com"
    mailer.text = url
    mailer.tokenize_urls!("http://m.wieck.com")

    assert_equal("http://m.wieck.com/m/#{mailer.envelope_id}?r=#{CGI.escape([url].pack("m"))}", mailer.text)
  end

  def test_tokenize_urls_with_html
    mailer = Wheels::Mailer.new
    url = "http://test.com"
    mailer.rawhtml = "<a href=\"#{url}\">Link</a>"
    mailer.tokenize_urls!("http://m.wieck.com")

    assert_equal("<a href=\"http://m.wieck.com/m/#{mailer.envelope_id}?r=#{CGI.escape([url].pack("m"))}\">Link</a>", mailer.html)
  end

  def test_tokenize_urls_with_https
    mailer = Wheels::Mailer.new
    url = "https://test.com"
    mailer.text = url
    mailer.tokenize_urls!("http://m.wieck.com")

    assert_equal("http://m.wieck.com/m/#{mailer.envelope_id}?r=#{CGI.escape([url].pack("m"))}", mailer.text)
  end

  ##
  # Fixing an issue reported by Drew where links would be blown away.
  # 
  def test_tokenize_urls_with_link_as_name
    mailer = Wheels::Mailer.new
    url = "http://test.com"
    mailer.rawhtml = "<a href=\"#{url}\">#{url}</a>"
    mailer.tokenize_urls!("http://m.wieck.com")

    url = "http://m.wieck.com/m/#{mailer.envelope_id}?r=#{CGI.escape([url].pack("m"))}"
    assert_equal("<a href=\"#{url}\">#{url}</a>", mailer.html)
  end

end