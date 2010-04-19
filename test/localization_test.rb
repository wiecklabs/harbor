require "pathname"
require Pathname(__FILE__).dirname + "helper"
require "harbor/test/test"
class LocalizationStringTest < Test::Unit::TestCase
  
  def test_localized_string_translated
    translated_string = Harbor::Locale::LocalizedString.new('I am the walrus', true)
    assert translated_string.translated?
  end
  
  def test_localized_string_to_s
    translated_string = Harbor::Locale::LocalizedString.new('I am the walrus', true)
    assert_equal translated_string.to_s, 'I am the walrus'
  end
  
  def test_localized_string_untranslated
    untranslated_string = Harbor::Locale::LocalizedString.new('I am the walrus')
    assert !untranslated_string.translated?
  end
  
  def test_localized_string_to_s
    untranslated_string = Harbor::Locale::LocalizedString.new('I am the walrus')
    assert_equal untranslated_string.to_s, "<span class='untranslated'>I am the walrus</span>"
  end
  
  def test_should_raise_if_localized_string_initialized_with_something_not_a_string
    assert_raises ArgumentError do
      Harbor::Locale::LocalizedString.new(nil)
    end
  end
  
end

class LocalizationHelpersTest < Test::Unit::TestCase

  class LocalizationTestViewContext
    include Harbor::ViewContext::Helpers::Localization
    
    attr_reader :request, :view
    
    def initialize(request, view)
      @request = request
      @view = view
    end
    
    def locale
      @request.locale
    end
    
  end

  def setup
    @locale = Harbor::Locale.new
    @locale.culture_code        = 'en-US'
    @locale.time_formats        = {:long => "%m/%d/%Y %h:%m:%s", :default => "%h:%m:%s"}
    @locale.date_formats        = {:default => '%m/%d/%Y'}
    @locale.decimal_formats     = {:default => "%s", :currency => "$%01.2f", :percent => "%s%%"}
    @locale.wday_names          = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
    @locale.wday_abbrs          = %w(Sun Mon Tue Wed Thur Fri Sat)
    @locale.month_names         = %w{January February March April May June July August September October November December}
    @locale.month_abbrs         = %w{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec}

    Harbor::Locale.register(@locale)
    @request = get("/", {})
    @view = Harbor::View.new('admin/index')
    @view_context = LocalizationTestViewContext.new(@request, @view)
  end
  
  def breakdown
    Harbor::Locale.flush!
  end
  
  def test_translation_failure
    assert_equal Harbor::Locale::LocalizedString.new('organization', false), @view_context.t('organization')
  end

  def test_direct_translation
    @locale.set('organization', 'organisation')
    assert_equal Harbor::Locale::LocalizedString.new('organisation', true), @view_context.t('organization')
    assert @view_context.t('organization').translated?
  end

  def test_translation_interpolation
    @locale.set("{{birthday}} is my birthday", "{{birthday}} is the day you should give me gifts")
    date = Date.civil(2010, 4, 15)
    expectation = Harbor::Locale::LocalizedString.new("04/15/2010 is the day you should give me gifts", true)
    assert_equal expectation, @view_context.t("{{birthday}} is my birthday", :birthday => date)
  end
  
  def test_direct_interpolation
    assert_equal @locale.localize(10), '10'
    assert_equal @locale.localize(10.0), '10.0'
    assert_equal @locale.localize(10.0, :currency), "$10.00"
    assert_equal @locale.localize(10.0, :percent), "10.0%"
  end
  
  # I think I should stop there...further testing here would just reproduce what's already in localization_test.rb

  def get(path, options = {})
    request(path, "GET", options)
  end

  def request(path, method, options)
    Harbor::Request.new(Class.new, Rack::MockRequest.env_for(path, options.merge(:method => method)))
  end

end
