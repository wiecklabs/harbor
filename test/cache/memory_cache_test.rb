require "pathname"
require Pathname(__FILE__).dirname.parent + "helper"
require Pathname(__FILE__).dirname + 'synchronized_cache_test_bootstrap'

class MemoryCacheTest < MiniTest::Unit::TestCase

  include SynchronizedCacheTestBootstrap

  def setup
    @store = Harbor::Cache::Memory.new
    @cache = Harbor::Cache.new(@store)
  end

  def test_keys_matching
    @store.put('test_key', 10, 100, CACHE_CONTENT, Time.now)

    assert !@store.keys_matching(/.*test_key.*/).empty?
  end

end
