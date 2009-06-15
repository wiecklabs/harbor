require "pathname"
require Pathname(__FILE__).dirname.parent + "helper"

require "harbor/file_store"
require "harbor/file_store/mosso"

class MossoFileStoreTest < Test::Unit::TestCase

  def setup
    @local = Harbor::FileStore::Local.new(Pathname(__FILE__).dirname)
    @mosso = Harbor::FileStore::Mosso.new("wieck", ENV["MOSSO_API_KEY"], "harbor-unittests")
  end

  def test_mosso_file_store_connects
    assert_nothing_raised { @mosso.send(:connect!) }
    assert(@mosso.send(:connected?))
  end

  def test_put
    filename = "__local_file_store_test__"
    file = File.open(__FILE__)

    assert_nothing_raised do
      @mosso.put(filename, file)
    end

    assert(@mosso.container.object_exists?(filename))
  end

  def test_put_with_harbor_file
    filename = File.basename(__FILE__)
    file = @local.get(filename)

    assert(file.is_a?(Harbor::FileStore::File))

    assert_nothing_raised do
      @mosso.put(filename, file)
    end

    assert(@mosso.container.object_exists?(filename))
  end

  def test_delete
    filename = "__local_file_store_test__"
    file = File.open(__FILE__)

    @mosso.put(filename, file)

    assert(@mosso.container.object_exists?(filename))

    @mosso.delete(filename)

    assert(!@mosso.container.object_exists?(filename))
  end

  def test_exists
    filename = "__local_file_store_test__"
    file = File.open(__FILE__)

    assert_equal(@mosso.container.object_exists?(filename), @mosso.exists?(filename))

    @mosso.put(filename, file)

    assert_equal(@mosso.container.object_exists?(filename), @mosso.exists?(filename))
  end

  def test_read
    filename = "__local_file_store_test__"
    file = File.open(__FILE__)

    @mosso.put(filename, file)

    f = @mosso.get(filename)

    file.seek(0)
    assert_equal(file.read, f.read)
  end

  def test_copy_from_mosso_to_local
    filename = "__local_file_store_test__"
    file = File.open(__FILE__)

    @mosso.put(filename, file)

    f = @mosso.get(filename)

    @local.put(filename, f)

    assert_equal(f.read, @local.get(filename).read)

    @local.delete(filename)
  end

end