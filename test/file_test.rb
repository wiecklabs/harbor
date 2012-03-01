require_relative "helper"
require "tempfile"

class HarborFileTest < MiniTest::Unit::TestCase
  def setup
  end

  def test_move_with_default_permissions
    tempfile = Tempfile.new("file_test")
    assert_equal("100600", "%o" % File.stat(tempfile.path).mode)

    Harbor::File.move(tempfile.path, "tempfile")

    assert_equal("100%o" % (0666 - File.umask), "%o" % File.stat("tempfile").mode)

    FileUtils.rm("tempfile")
  ensure
    tempfile.close
  end

  def test_move_with_custom_permissions
    tempfile = Tempfile.new("file_test")
    assert_equal("100600", "%o" % File.stat(tempfile.path).mode)

    Harbor::File.move(tempfile.path, "tempfile", 0777)

    assert_equal("100777", "%o" % File.stat("tempfile").mode)

    FileUtils.rm("tempfile")
  ensure
    tempfile.close
  end

  def test_rmdir_p
    FileUtils.mkdir_p("testing/mkdir/p")

    assert(File.directory?("testing/mkdir/p"))

    Harbor::File.rmdir_p("testing/mkdir/p")

    assert(!File.directory?("testing/mkdir/p"))
    assert(!File.directory?("testing/mkdir"))
    assert(!File.directory?("testing"))
  end

  def test_move_safely
    tempfile = Tempfile.new("file_test")
    destination = "testing/move/safely.txt"

    assert_raises(RuntimeError) do
      Harbor::File.move_safely(tempfile.path, destination) do
        raise
      end
    end

    assert(File.file?(tempfile.path))
    assert(!File.directory?("testing"))

    Harbor::File.move_safely(tempfile.path, destination) do
    end

    assert(File.file?(destination))

    FileUtils.rm(destination)
    Harbor::File.rmdir_p(File.dirname(destination))
  ensure
    tempfile.close
  end
end
