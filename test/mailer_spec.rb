#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::Mailer do

  it "must tokenize urls inside plain text portion of mailer" do
    mailer = Harbor::Mailer.new
    url = "http://test.com"
    mailer.text = url
    mailer.tokenize_urls!("http://m.wieck.com/m/%s?r=%s")

    mailer.text.must_equal(
      "http://m.wieck.com/m/#{CGI.escape(mailer.envelope_id)}?r=#{CGI.escape([url].pack("m"))}"
    )
  end

  it "must tokenize urls inside HTML portion of mailer" do
    mailer = Harbor::Mailer.new
    url = "http://test.com"
    mailer.html = "<a href=\"#{url}\">Link</a>"
    mailer.tokenize_urls!("http://m.wieck.com/m/%s?r=%s")

    mailer.html.must_equal(
      "<a href=\"http://m.wieck.com/m/#{CGI.escape(mailer.envelope_id)}?r=#{CGI.escape([url].pack("m"))}\">Link</a>"
    )
  end

  it "must tokenize HTTPS urls" do
    mailer = Harbor::Mailer.new
    url = "https://test.com"
    mailer.text = url
    mailer.tokenize_urls!("http://m.wieck.com/m/%s?r=%s")

    mailer.text.must_equal(
      "http://m.wieck.com/m/#{CGI.escape(mailer.envelope_id)}?r=#{CGI.escape([url].pack("m"))}"
    )
  end

  ##
  # Fixing an issue reported by Drew where links would be blown away.
  # 
  it "must not munge URLs used as anchor tag inner-text" do
    mailer = Harbor::Mailer.new
    destination_url = "http://test.com"

    mailer.html = "<a href=\"#{destination_url}\">#{destination_url}</a>"
    mailer.tokenize_urls!("http://m.wieck.com/m/%s?r=%s")

    url = "http://m.wieck.com/m/#{CGI.escape(mailer.envelope_id)}?r=#{CGI.escape([destination_url].pack("m"))}"
    mailer.html.must_equal "<a href=\"#{url}\">#{destination_url}</a>"
  end

  ##
  # Fixing an issue where the regex wasn't robust enough to handle tags after the link tag
  # 
  it "must tokenize urls with other elements after the anchor on the same line" do
    mailer = Harbor::Mailer.new
    url = "http://test.com"
    mailer.html = "<p><a href=\"#{url}\">Link</a></p>"
    mailer.tokenize_urls!("http://m.wieck.com/m/%s?r=%s")

    mailer.html.must_equal(
      "<p><a href=\"http://m.wieck.com/m/#{CGI.escape(mailer.envelope_id)}?r=#{CGI.escape([url].pack("m"))}\">Link</a></p>"
    )
  end

  it "must use mail-filters to set overridden recipient address" do
    filter = Harbor::MailFilters::DeliveryAddressFilter.new("dev@example.com", /@example.com/)
    mailer = Harbor::Mailer.new
    
    mailer.text = "asdf"
    mailer.to = "test@notexample.com"
    mailer = filter.apply(mailer)

    mailer.to.wont_equal "test@notexample.com"
    mailer.get_header('X-Overridden-To').must_equal 'test@notexample.com'
    mailer.to.must_equal "dev@example.com"
    mailer.get_header('X-Overridden-To').wont_equal 'dev@example.com'
  end

  it "must not override whitelisted addresses when using mail-filters" do
    filter = Harbor::MailFilters::DeliveryAddressFilter.new("test@example.com", /@example.com/)
    mailer = Harbor::Mailer.new
    
    mailer.to = "dev@example.com"
    mailer = filter.apply(mailer)

    mailer.to.wont_equal "test@example.com"
    mailer.to.must_equal "dev@example.com"
  end
end