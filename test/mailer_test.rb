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

  ##
  # Fixing an issue where the regex wasn't robust enough to handle tags after the link tag
  # 
  def test_tokenize_urls_with_tags_after_anchor_tag
    mailer = Harbor::Mailer.new
    url = "http://test.com"
    mailer.html = "<p><a href=\"#{url}\">Link</a></p>"
    mailer.tokenize_urls!("http://m.wieck.com/m/%s?r=%s")

    assert_equal("<p><a href=\"http://m.wieck.com/m/#{CGI.escape(mailer.envelope_id)}?r=#{CGI.escape([url].pack("m"))}\">Link</a></p>", mailer.html)
  end

  def test_mail_filter_overrides_recipient_address_and_sets_overridden_header
    filter = Harbor::MailFilters::DeliveryAddressFilter.new("dev@example.com", /@example.com/)
    mailer = Harbor::Mailer.new
    
    mailer.text = "asdf"
    mailer.to = "test@notexample.com"
    mailer = filter.apply(mailer)
    
    assert_not_equal('test@notexample.com', mailer.to)
    assert_equal('test@notexample.com', mailer.get_header('X-Overridden-To'))
    assert_equal('dev@example.com', mailer.to)
    assert_not_equal('dev@example.com', mailer.get_header('X-Overridden-To'))
  end

  def test_mail_filter_does_not_override_whitelisted_address
    filter = Harbor::MailFilters::DeliveryAddressFilter.new("test@example.com", /@example.com/)
    mailer = Harbor::Mailer.new
    
    mailer.to = "dev@example.com"
    mailer = filter.apply(mailer)
    
    assert_not_equal('test@example.com', mailer.to)
    assert_equal('dev@example.com', mailer.to)
  end
end