require "pathname"
require Pathname(__FILE__).dirname.parent + "helper"

class MemoryCacheTest < Test::Unit::TestCase

  CACHE_CONTENT = 'Lorem ipsum dolor sit amet'

  def setup
    @cache = Harbor::Cache::Memory.new
  end

  def teardown
  end

  def test_get_returns_nil
    assert_equal(nil, @cache.get('non-existant-key'))
  end

  def test_put
    assert_raise(ArgumentError) { @cache.put(nil, CACHE_CONTENT, 1, 1) }

    assert_raise(ArgumentError) { @cache.put('key', CACHE_CONTENT, nil) }
    assert_raise(ArgumentError) { @cache.put('key', CACHE_CONTENT, -1) }
    assert_raise(ArgumentError) { @cache.put('key', CACHE_CONTENT, 0) }

    assert_raise(ArgumentError) { @cache.put('key', CACHE_CONTENT, 1, -1) }
    assert_raise(ArgumentError) { @cache.put('key', CACHE_CONTENT, 1, 0) }

    assert_nothing_raised { @cache.put('key', CACHE_CONTENT, 1) }
    assert_nothing_raised { @cache.put('key', CACHE_CONTENT, 1, 5) }
  end

  def test_content_is_retrievable_before_ttl
    @cache.put('key', CACHE_CONTENT, 3)
    Time.warp(1) { assert_equal(CACHE_CONTENT, @cache.get('key').content) }
  end

  def test_content_is_not_retrievable_after_ttl
    @cache.put('key', CACHE_CONTENT, 3)
    Time.warp(4) { assert_equal(nil, @cache.get('key')) }
  end

  def test_content_is_retrievable_before_maximum_age_but_not_after
    @cache.put('key', CACHE_CONTENT, 3, 6)
    Time.warp(2) { assert_equal(CACHE_CONTENT, @cache.get('key').content) }
    Time.warp(4) { assert_equal(CACHE_CONTENT, @cache.get('key').content) }
    Time.warp(6) { assert_equal(nil, @cache.get('key')) }
  end

  def test_delete_returns_nil
    assert_equal(nil, @cache.delete('key'))
    assert_equal(nil, @cache.delete('some-key-that-was-never-available' + Time.now.to_s))
  end

  def test_content_is_not_retrievable_after_delete
    @cache.put('key', CACHE_CONTENT, 3)
    @cache.delete('key')
    assert_equal(nil, @cache.get('key'))
  end

end