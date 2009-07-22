require "pathname"
require Pathname(__FILE__).dirname.parent + "helper"
require Pathname(__FILE__).dirname + 'synchronized_cache_test_bootstrap'

class MemoryCacheTest < Test::Unit::TestCase

  include SynchronizedCacheTestBootstrap

  def setup
    @cache = Harbor::Cache.new(Harbor::Cache::Memory.new)
  end

end