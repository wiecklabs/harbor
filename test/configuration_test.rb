require "pathname"
require Pathname(__FILE__).dirname + "helper"

class ConfigurationTest < Test::Unit::TestCase
  
  # config.data.connection_string = "postgres://localhost/demo"
  # 
  # config.controllers.admin.photos.show(*args)
  # 
  # config.views
  # config.routes
  # config.hostname
  # config.mail.server
  
  def setup
    config.load!(Harbor::env_path)
  end
  
  def test_container_is_present
    assert_kind_of(Harbor::Configuration, config)
  end

  def test_debug_default
    assert(!config.debug?)
  end
  
  def test_default_locale_is_english
    assert_equal(config.locales.default, Harbor::Locale["en-US"])
  end
  
  def test_default_cache_is_present
    assert_kind_of(Harbor::Cache, config.cache)
  end
end