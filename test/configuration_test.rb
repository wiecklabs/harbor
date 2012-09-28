require_relative "helper"

class ConfigurationTest < MiniTest::Unit::TestCase

  # config.data.connection_string = "postgres://localhost/demo"
  #
  # config.controllers.admin.photos.show(*args)
  #
  # config.views
  # config.routes
  # config.hostname
  # config.mail.server

  def initialize(*args)
    config.load!(Pathname(__FILE__).dirname.parent + "env")
    super
  end

  def test_container_is_present
    assert_kind_of(Harbor::Configuration, config)
  end

  def test_debug_default
    assert(!config.debug?)
  end

  def test_default_locale_is_english
    assert_equal(config.locales.default, Harbor::Locale["en_US"])
  end

  def test_hostname_is_present
    assert_equal(`hostname`.strip, config.hostname)
  end

  def test_method_missing_setter
    config.test_setter = true

    assert(config.test_setter)
  end

  def test_can_re_register_services
    config.reregistered = false
    config.reregistered = true

    assert(config.reregistered)
  end

  def test_unset_keys_return_configurations
    config.unset_key
    assert config.unset_key.is_a? Harbor::Configuration
  end

  def test_unset_keys_can_be_chained
    assert config.tomato.juicy = true
  end
end
