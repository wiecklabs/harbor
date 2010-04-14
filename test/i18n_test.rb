require "pathname"
require Pathname(__FILE__).dirname + "helper"

class I18nTest < Test::Unit::TestCase
  
  def setup
    Harbor::Locale.activate!("en-US","ja","en-GB","en-AU")
  end
  
  def test_preferred_locales_returns_default_locale_when_none_specified
    test = Harbor::I18n.new(Harbor::Locale.default)
    assert_equal test, get("/", {'HTTP_ACCEPT_LANGUAGE' => ''}).preferred_locales
    assert_equal test, get("/", {'HTTP_ACCEPT_LANGUAGE' => nil}).preferred_locales
  end
  
  def test_preferred_locales_returns_default_locale_when_invalid_locale_string_provided
    assert_equal Harbor::I18n.new(Harbor::Locale.default), get("/", {'HTTP_ACCEPT_LANGUAGE' => 'ru'}).preferred_locales
  end
  
  def test_preferred_locales_returns_harbor_locales_as_specified_in_headers
    locales = Harbor::I18n.new(Harbor::Locale['en-AU'], Harbor::Locale['en-US'])
    
    assert_equal get("/", {'HTTP_ACCEPT_LANGUAGE' => 'en-AU,en-US;q=0.9'}).preferred_locales, locales
    assert_equal get("/", {'HTTP_ACCEPT_LANGUAGE' => 'en-AU;q=0.9,en-US;q=0.8'}).preferred_locales, locales
  end
  
  def test_preferred_locales_should_sort_by_q
    locales = Harbor::I18n.new(Harbor::Locale['en-US'], Harbor::Locale['en-AU'])
    assert_equal get("/", {'HTTP_ACCEPT_LANGUAGE' => 'en-AU;q=0.8,en-US;q=0.9'}).preferred_locales, locales
  end
  
  def get(path, options = {})
    request(path, "GET", options)
  end

  def post(path, options = {})
    request(path, "POST", options)
  end

  def request(path, method, options)
    Harbor::Request.new(Class.new, Rack::MockRequest.env_for(path, options.merge(:method => method)))
  end
  
  
end