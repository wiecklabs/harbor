#!/usr/bin/env jruby

require_relative "helper"
require "tempfile"

describe Harbor::File do

  it "moves with default permissions" do
    begin
      tempfile = Tempfile.new("file_test")

      ("%o" % File.stat(tempfile.path).mode).must_equal "100600"

      Harbor::File.move(tempfile.path, "tempfile")

      ("%o" % File.stat("tempfile").mode).must_equal("100%o" % (0666 - File.umask))

      FileUtils.rm("tempfile")
    ensure
      tempfile.close
    end
  end

  it "moves with custom permissions" do
    begin
      tempfile = Tempfile.new("file_test")

      ("%o" % File.stat(tempfile.path).mode).must_equal "100600"

      Harbor::File.move(tempfile.path, "tempfile", 0777)

      ("%o" % File.stat("tempfile").mode).must_equal "100777"

      FileUtils.rm("tempfile")
    ensure
      tempfile.close
    end
  end

  it "must rmdir" do
    FileUtils.mkdir_p("testing/mkdir/p")

    Pathname("testing/mkdir/p").must_be :directory

    Harbor::File.rmdir_p("testing/mkdir/p")

    Pathname("testing/mkdir/p").wont_be :directory
    Pathname("testing/mkdir").wont_be :directory
    Pathname("testing").wont_be :directory
  end

  it "must move safely" do
    begin
      tempfile = Tempfile.new("file_test")
      destination = "testing/move/safely.txt"

      -> do
        Harbor::File.move_safely(tempfile.path, destination) do
          raise
        end
      end.must_raise RuntimeError

      Pathname(tempfile.path).must_be :file
      Pathname("testing").wont_be :directory

      Harbor::File.move_safely(tempfile.path, destination) do
      end

      Pathname(destination).must_be :file

      FileUtils.rm(destination)
      Harbor::File.rmdir_p(File.dirname(destination))
    ensure
      tempfile.close
    end
  end

end