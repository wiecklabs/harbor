require "pathname"
require Pathname(__FILE__).dirname.parent + "helper"

require "harbor/file_store"

class LocalFileStoreTest < Test::Unit::TestCase

  def setup
    @tmp = Harbor::FileStore::Local.new("/tmp/__file_store_test__")
  end

  def teardown
    FileUtils.rm("/tmp/__file_store_test__/__local_file_store_test__") if File.exists?("/tmp/__file_store_test__/__local_file_store_test__")
  end

  def test_put_with_file
    filename = "__local_file_store_test__"
    file = File.open(__FILE__)

    assert_nothing_raised do
      @tmp.put(filename, file)
    end

    assert(File.exists?("/tmp/__file_store_test__/#{filename}"), "File should exist: /tmp/__file_store_test__/#{filename}")
  end

  def test_put_with_directory_structure
    filename = "__dir__/__local_file_store_test__"
    file = File.open(__FILE__)

    assert_nothing_raised do
      @tmp.put(filename, file)
    end

    assert(File.exists?("/tmp/__file_store_test__/#{filename}"))
  ensure
    FileUtils.rm("/tmp/__file_store_test__/#{filename}")
    Harbor::File.rmdir_p("/tmp/__file_store_test__/__dir__")
  end

  def test_delete_with_directory_structure
    filename = "__dir__/__local_file_store_test__"
    file = File.open(__FILE__)

    @tmp.put(filename, file)
    @tmp.delete(filename)

    assert(!@tmp.exists?(filename))
    assert(!File.exists?("/tmp/__file_store_test__/#{filename}"))
    assert(!File.exists?("/tmp/__file_store_test__/__dir__"))
  ensure
    FileUtils.rm("/tmp/__file_store_test__/#{filename}") rescue nil
    Harbor::File.rmdir_p("/tmp/__file_store_test__/__dir__") rescue nil
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

  def test_cleanup_with_no_cache_size_option
    assert_equal(false, @tmp.send(:cleanup))
  end

  def test_cleanup_with_less_usage_than_cache_size
    @tmp.options[:cache_size] = 1024 * 1024 * 1024
    assert_equal(false, @tmp.send(:cleanup))
  ensure
    @tmp.options[:cache_size] = nil
  end

  def test_cleanup_with_more_usage_than_cache_size_but_within_cache_time
    @tmp.options[:cache_size] = 20

    File.open(@tmp.path + "__testing_cleanup__", "w") { |f| f.write('a' * 120) }

    assert(@tmp.send(:cleanup))
    assert(@tmp.exists?("__testing_cleanup__"))
  ensure
    @tmp.options[:cache_size] = nil
    File.rm(@tmp.path + "__testing_cleanup__") rescue nil
  end

  def test_cleanup_with_more_usage_than_cache_size_and_outside_cache_time
    @tmp.options[:cache_size] = 20
    @tmp.options[:cache_time] = 1

    File.open(@tmp.path + "__testing_cleanup__", "w") { |f| f.write('a' * 120) }

    sleep(2)

    assert(@tmp.send(:cleanup))
    assert(!@tmp.exists?("__testing_cleanup__"))
  ensure
    @tmp.options[:cache_size] = nil
    @tmp.options[:cache_time] = nil
    File.rm(@tmp.path + "__testing_cleanup__") rescue nil
  end

end