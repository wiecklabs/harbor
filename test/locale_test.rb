require "pathname"
require Pathname(__FILE__).dirname + "helper"

class LocaleTest < Test::Unit::TestCase
  
  def setup
    @locale = Harbor::Locale.new
    @locale.culture_code        = 'en-US'
    @locale.time_formats        = {:long => "%m/%d/%Y %h:%m:%s", :default => "%h:%m:%s"}
    @locale.date_formats        = {:default => '%m/%d/%Y'}
    @locale.decimal_formats     = {:default => "%8.2f", :currency => "$%8.2f", :percent => "%d%%"}
    @locale.wday_names          = %w(Sunday Monday Tuesday Wednesday Thursday Friday Saturday)
    @locale.wday_abbrs          = %w(Sun Mon Tue Wed Thur Fri Sat)
    @locale.month_names         = %w{January February March April May June July August September October November December}
    @locale.month_abbrs         = %w{Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec}

    Harbor::Locale.register(@locale)
  end
  
  def breakdown
    Harbor::Locale.flush!
  end
  
  # ======= testing the giant hash in the sky
  def test_setting_a_replacement
    @locale.set('organization', 'organisation')
    assert @locale.entries['organization'], 'organisation'
  end
  
  def test_getting_a_replacement
    @locale.entries['organization'] = 'organisation'
    assert @locale.get('organization'), 'organisation'
  end
  
  def test_loading_replacements_from_hash
    @locale.load({'organizations' => 'organisations', 'organization' => 'organisation'})
    assert @locale.get('organization'), 'organisation'
    assert @locale.get('organizations'), 'organisation'
  end
  # ========
  
  
  def test_returns_key_when_no_translation_specified
    assert @locale.translate('organization'), 'organization'
  end
  
  def test_returns_translation_when_specified
    @locale.set('organization', 'organisation')
    assert @locale.translate('organization'), 'organisation'
  end
  
  def test_returns_translation_when_path_specified
    @locale.set("account/organization", 'organisation')
    assert @locale.translate('account/organization'), 'organisation'
  end
  
  def test_returns_translation_by_shifting_paths
    @locale.set('organization', 'organisation')
    assert @locale.translate('account/organization'), 'organisation'
  end
  
  def test_interpolates_named_positions
    assert @locale.translate('{{count}} records', {:count => 12}), '12 records'
    assert @locale.translate('{{count}} records, {{total}} pages', {:count => 12, :total => 24}), '12 records, 24 pages'
  end
  
  def test_localize_values_before_interpolating_named_positions
    assert @locale.translate('{{decimal}} is a decimal', :decimal => 12.2), "12.2 is a decimal"
    assert @locale.translate('{{date}} is d-day', :date => Date.civil(2010, 4, 15)), "4/15/2010 is d-day"
    assert @locale.translate('{{time}} is t-time', :time => Time.at(946702800)), "11:00 PM is t-time"
  end
  
  def test_localizes_decimals
    assert @locale.localize(10), '10'
    assert @locale.localize(10.0), '10.0'
    assert @locale.localize(10.0, :currency), "$10.00"
    assert @locale.localize(10.0, :percent), "10.0%"
  end
  
  def test_localizes_dates
    date = Date.civil(2010, 4, 15)
    date_localization = "4/15/2010"
    
    assert @locale.localize(date), date_localization
  end
  
  def test_localizes_times
    time = Time.at(946702800) # 1999-12-31 23:00:00
    default_localization = "11:00 PM"
    long_localization = "12/31/1999 11:00 PM"
    
    assert @locale.localize(time), default_localization
    assert @locale.localize(time, :long), long_localization
  end
end