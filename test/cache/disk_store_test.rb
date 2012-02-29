require "pathname"
require Pathname(__FILE__).dirname.parent + "helper"

class CacheDiskStoreTestTest < MiniTest::Unit::TestCase

  CACHE_CONTENT = 'Lorem ipsum dolor sit amet'

  def setup
    @path = File.join(Dir::tmpdir, "cache_test")
    FileUtils.rm(Dir[Pathname(@path) + "*"].entries) # clearing the disk-cache between tests
    @store = Harbor::Cache::Disk.new(@path)
  end

  def test_returns_nil_for_missing_item
    assert_nil(@store['not_here'])
  end

  def test_stores_content
    ttl = 10
    maximum_age = 100
    cached_at = Time.now

    item = @store.put('test_key', ttl, maximum_age, CACHE_CONTENT, cached_at)
    ultimate_expiration_time = item.ultimate_expiration_time

    item = @store.get('test_key')

    assert_equal(CACHE_CONTENT, item.content)
    assert_equal(ttl, item.ttl)
    assert_equal(maximum_age, item.maximum_age)
    assert_equal(ultimate_expiration_time.to_i, item.ultimate_expiration_time.to_i)
    assert_equal(cached_at.to_i, item.cached_at.to_i)
  end

  def test_keys_matching
    @store.put('test_key', 10, 100, CACHE_CONTENT, Time.now)

    assert !@store.keys_matching(/.*test_key.*/).empty?
  end

end
