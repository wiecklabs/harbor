require "pathname"
require Pathname(__FILE__).dirname.parent + "helper"
require Pathname(__FILE__).dirname + 'synchronized_cache_test_bootstrap'

class DiskCacheTest < MiniTest::Unit::TestCase

  include SynchronizedCacheTestBootstrap

  def setup
    @path = Pathname(Dir::tmpdir) + "cache_test"
    FileUtils.rm(Dir[@path + "*"])

    @cache = Harbor::Cache.new(Harbor::Cache::Disk.new(@path))
  end

end