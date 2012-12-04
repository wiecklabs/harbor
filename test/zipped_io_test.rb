require "pathname"
require Pathname(__FILE__).dirname + "helper"
# require Pathname(__FILE__).dirname.parent + "harbor" + "zipped_io"

class ZippedIOTest < Test::Unit::TestCase

  def setup
  end

  def teardown
  end

  def test_create_a_simple_zip_file
    file = Harbor::File.new(Pathname(__FILE__).dirname + "samples" + "volcanoUPI_800x531.jpg")
    file2 = Harbor::File.new(Pathname(__FILE__).dirname + "application_test.rb")
    zip = Harbor::ZippedIO.new([file, file2])
    size = zip.size
    ::File.open("/tmp/ziptest_#{`uuidgen`.chomp}.zip", "w") do |file|
      zip.each do |data|
        file.write(data)
      end
    end
  end

end
