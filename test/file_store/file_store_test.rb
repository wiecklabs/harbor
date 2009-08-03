require "pathname"
require Pathname(__FILE__).dirname.parent + "helper"

require "harbor/file_store"

class FileStoreTest < Test::Unit::TestCase

  def teardown
    Harbor::FileStore.file_stores.clear
  end

  def test_register_store_by_name
    object = Class.new.new

    Harbor::FileStore.register("store", object)
    assert_equal(object, Harbor::FileStore.file_stores["store"])
    assert_equal(object, Harbor::FileStore["store"])
  end

  def test_put_must_be_defined
    store = Harbor::FileStore.new
    assert_raise(NotImplementedError) { store.put("path", Class.new.new) }
  end

  def test_get_returns_harbor_file
    flunk("API has changed. Do we no longer need this?")

    store = Harbor::FileStore.new
    assert(store.get("path").is_a?(Harbor::FileStore::File))
  end

  def test_delete_must_be_defined
    store = Harbor::FileStore.new
    assert_raise(NotImplementedError) { store.delete("path") }
  end

  def test_open_must_be_defined
    store = Harbor::FileStore.new
    assert_raise(NotImplementedError) { store.open("path") }
  end

  def test_size_must_be_defined
    store = Harbor::FileStore.new
    assert_raise(NotImplementedError) { store.size("path") }
  end

  def test_exists_must_be_defined
    store = Harbor::FileStore.new
    assert_raise(NotImplementedError) { store.exists?("path") }
  end

  def test_local_must_be_defined
    store = Harbor::FileStore.new
    assert_raise(NotImplementedError) { store.local? }
  end

end