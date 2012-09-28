require_relative "helper"

class BlockIOTest < MiniTest::Unit::TestCase

  def setup
    @original_block_size = Harbor::BlockIO::block_size
    $VERBOSE, verbose = nil, $VERBOSE
    Harbor::BlockIO::block_size = 50
    $VERBOSE = verbose
  end

  def teardown
    $VERBOSE, verbose = nil, $VERBOSE
    Harbor::BlockIO::block_size = @original_block_size
    $VERBOSE = verbose
  end

  def test_reading_a_file
    io = Harbor::BlockIO.new(__FILE__)
    refute_nil(io.to_s =~ /test_reading_a_file/)
  end

  def test_reporting_a_file_size
    io = Harbor::BlockIO.new(__FILE__)
    assert_equal(File.size(__FILE__), io.size)
  end

  def test_iterating_over_a_file_in_chunks
    meaningless_data = File.read(__FILE__)
    block_io_txt = Pathname(__FILE__).dirname + "samples" + "block_io.txt"
    FileUtils.mkdir_p(block_io_txt.parent)

    File::open(block_io_txt, "w+") do |file|
      100.times do
        file << meaningless_data
        file << rand()
      end
    end

    byte_size = 0

    Harbor::BlockIO.new(block_io_txt).each do |chunk|
      assert_operator(chunk.size, :<=, Harbor::BlockIO::block_size)
      byte_size += chunk.size
    end

    assert_equal(File.size(block_io_txt), byte_size)

    FileUtils::rm(block_io_txt)
  end

  def test_iterating_over_a_string_io_in_chunks
    meaningless_data = File.read(__FILE__)
    block_io_txt = Pathname(__FILE__).dirname + "samples" + "block_io.txt"
    FileUtils.mkdir_p(block_io_txt.parent)

    File::open(block_io_txt, "w+") do |file|
      100.times do
        file << meaningless_data
        file << rand()
      end
    end

    byte_size = 0

    Harbor::BlockIO.new(StringIO.new(File.read(block_io_txt))).each do |chunk|
      assert_operator(chunk.size, :<=, Harbor::BlockIO::block_size)
      byte_size += chunk.size
    end

    assert_equal(File.size(block_io_txt), byte_size)

    FileUtils::rm(block_io_txt)
  end

end
