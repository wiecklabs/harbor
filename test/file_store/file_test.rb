require "pathname"
require Pathname(__FILE__).dirname.parent + "helper"

require "harbor/file_store"

class FileStoreFileTest < Test::Unit::TestCase

  def setup
    @tmp = Harbor::FileStore::Local.new("/tmp")
    @tmp.put("__file_store_file_test__", File.open(__FILE__))
  end

  def teardown
    FileUtils.rm("/tmp/__file_store_file_test__")
  end

  def test_read
    f = File.open("/tmp/__file_store_file_test__")

    file = Harbor::FileStore::File.new(@tmp, "__file_store_file_test__")

    assert_nothing_raised do
      assert_equal(f.read(1), file.read(1))
      assert_equal(f.read, file.read)
    end
  end

  def test_size
    file = Harbor::FileStore::File.new(@tmp, "__file_store_file_test__")

    assert_equal(File.size("/tmp/__file_store_file_test__"), file.size)
  end

end
