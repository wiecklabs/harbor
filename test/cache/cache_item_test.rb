require "pathname"
require Pathname(__FILE__).dirname.parent + "helper"

class CacheItemTest < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_accessors
    item = Harbor::Cache::Item.new('cache', 'key', 1, 2, Time.now)
    assert_respond_to(item, :key)
    assert_respond_to(item, :ttl)
    assert_respond_to(item, :maximum_age)
    assert_respond_to(item, :expires_at)
    assert_respond_to(item, :fresh?)
    assert_respond_to(item, :expired?)
    assert_respond_to(item, :content=)
    assert_respond_to(item, :content)
  end

  def test_initializer
    assert_raise(ArgumentError) { Harbor::Cache::Item.new('cache', nil, 1, 10, Time.now)}
    assert_raise(ArgumentError) { Harbor::Cache::Item.new('cache', 'key', 1, 0, Time.now)}
    assert_raise(ArgumentError) { Harbor::Cache::Item.new('cache', 'key', 1, 1, Time.now)}
    assert_raise(ArgumentError) { Harbor::Cache::Item.new('cache', 'key', 1, 10, nil)}

    assert_nothing_raised { Harbor::Cache::Item.new('cache', 'key', 1, 2) }
    assert_nothing_raised { Harbor::Cache::Item.new('cache', 'key', 1, 2, Time.now) }
  end

  def test_freshness
    item = Harbor::Cache::Item.new('cache', 'key', 3, nil)
    Time.warp(2) { assert_equal(true, item.fresh?) }
    Time.warp(3) { assert_equal(false, item.fresh?) }
  end

  def test_expired
    item = Harbor::Cache::Item.new('cache', 'key', 3, nil)
    Time.warp(2) { assert_equal(false, item.expired?) }
    Time.warp(3) { assert_equal(true, item.expired?) }
  end

  def test_bump_has_no_effect_unless_maximum_age_is_available
    cache_time = Time.now
    item = Harbor::Cache::Item.new('cache', 'key', 20, nil, cache_time)

    initial_expires_at = item.expires_at

    # Simulate a bump after 5 seconds
    Time.warp(5) { item.bump }

    assert_equal(initial_expires_at, item.expires_at)
  end

  def test_bump
    cache_time = Time.now
    ttl = 10
    item = Harbor::Cache::Item.new('cache', 'key', ttl, 30, cache_time)

    initial_expires_at = item.expires_at

    # Simulate a bump after 5 seconds (TTL is 10 seconds)
    Time.warp(cache_time + 5) { item.bump }

    # The new expiration time should be ahead of the old expiration time by
    # the TTL + the 5 second simulated time-passage
    assert_equal(cache_time + ttl + 5, item.expires_at)
  end

  def test_bump_maxes_out_at_maximum_age
    cache_time = Time.now
    maximum_age = 30
    item = Harbor::Cache::Item.new('cache', 'key', 10, maximum_age, cache_time)

    initial_expires_at = item.expires_at

    # Simulate a bump after 25 seconds (TTL is 10 seconds)
    Time.warp(cache_time + 25) { item.bump }

    # The new expiration time should be equal to the cache_time + maximum_age
    # because the cache_time + 10 after 25 seconds would be greater then maxiumu_age
    assert_equal(cache_time + maximum_age, item.expires_at)
  end


end
