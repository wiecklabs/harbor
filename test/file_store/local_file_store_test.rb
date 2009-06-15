require "pathname"
require Pathname(__FILE__).dirname.parent + "helper"

require "harbor/file_store"

class LocalFileStoreTest < Test::Unit::TestCase

  def setup
    @tmp = Harbor::FileStore::Local.new("/tmp")
  end

  def teardown
    FileUtils.rm("/tmp/__local_file_store_test__") if File.exists?("/tmp/__local_file_store_test__")
  end

  def test_put_with_file
    filename = "__local_file_store_test__"
    file = File.open(__FILE__)

    assert_nothing_raised do
      @tmp.put(filename, file)
    end

    assert(File.exists?("/tmp/#{filename}"), "File should exist: /tmp/#{filename}")
  end

  def test_delete
    filename = "__local_file_store_test__"
    @tmp.put(filename, File.open(__FILE__))

    assert(@tmp.exists?(filename))
    assert_nothing_raised do
      @tmp.delete(filename)
    end
    assert(!@tmp.exists?(filename))
  end

  def test_put_with_harbor_file
    filename = "__local_file_store_test__"
    file = File.open(__FILE__, "r")
    @tmp.put(filename, file)

    file = @tmp.get(filename)

    assert_nothing_raised do
      @tmp.put("#{filename}_1", file)
    end

    assert(@tmp.exists?("#{filename}_1"))
    @tmp.delete(file.path)
  end

  def test_exists
    filename = "__local_file_store_test__"
    @tmp.put(filename, File.open(__FILE__))

    assert(@tmp.exists?(filename))
  end

  def test_is_local
    assert(@tmp.local?)
  end

end