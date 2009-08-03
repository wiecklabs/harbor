require "pathname"
require Pathname(__FILE__).dirname.parent + "helper"

if !(ENV["MOSSO_USERNAME"] && ENV["MOSSO_API_KEY"] && ENV["MOSSO_CONTAINER"])
  puts("\n\033[0;33m*** Skipping mosso tests: MOSSO_USERNAME, MOSSO_API_KEY, and MOSSO_CONTAINER not set ***\033[0m\n\n")
else
  require "harbor/file_store"
  require "harbor/file_store/mosso"

  class MossoFileStoreTest < Test::Unit::TestCase

    def setup
      @local = Harbor::FileStore::Local.new(Pathname(__FILE__).dirname)
      @mosso = Harbor::FileStore::Mosso.new(ENV["MOSSO_USERNAME"], ENV["MOSSO_API_KEY"], ENV["MOSSO_CONTAINER"])

      Harbor::FileStore.register("local", @local)
      Harbor::FileStore.register("mosso", @mosso)
    end

    def teardown
      @mosso.delete("__local_file_store_test__") rescue nil
      Harbor::FileStore.file_stores.clear
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

      file.rewind

      f = @mosso.get(filename)

      @local.put(filename, f)

      assert_equal(f.read, @local.get(filename).read)

      @local.delete(filename)
    end

    def test_copy_on_read
      @mosso.options[:copy_on_read] = ["local"]
      filename = "__local_file_store_test__"
      file = File.open(__FILE__)

      @mosso.put(filename, file)

      f = @mosso.get(filename)
      f.read

      assert(@local.exists?(filename))
    ensure
      @mosso.delete(filename) rescue nil
      @local.delete(filename) rescue nil
      @mosso.options[:copy_on_read] = nil
    end

    def test_local_copy_on_write
      @local.options[:copy_on_write] = ["mosso"]

      filename = "__local_file_store_test__"
      file = File.open(__FILE__)

      @local.put(filename, file)

      assert(@mosso.exists?(filename))
    ensure
      @mosso.delete(filename) rescue nil
      @local.delete(filename) rescue nil
      @local.options[:copy_on_write] = nil
    end

    def test_mosso_copy_on_read_with_local_copy_on_write
      @mosso.options[:copy_on_read] = ["local"]
      @local.options[:copy_on_write] = ["mosso"]

      filename = "__local_file_store_test__"
      file = File.open(__FILE__)

      @local.put(filename, file)

      assert(@mosso.exists?(filename))
    end

  end
end