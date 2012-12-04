#!/usr/bin/env jruby

require "pathname"
require Pathname(__FILE__).dirname + "helper"

describe Harbor::BlockIO do

  before do
    @original_block_size = Harbor::BlockIO::block_size
    $VERBOSE, verbose = nil, $VERBOSE
    Harbor::BlockIO::block_size = 50
    $VERBOSE = verbose
  end

  after do
    $VERBOSE, verbose = nil, $VERBOSE
    Harbor::BlockIO::block_size = @original_block_size
    $VERBOSE = verbose
  end

  it "must read a file" do
    io = Harbor::BlockIO.new(__FILE__)
    io.to_s.must_match /test_reading_a_file/
  end

  it "must report proper file size" do
    io = Harbor::BlockIO.new(__FILE__)
    io.size.must_equal File.size(__FILE__)
  end

  it "must chunk a file" do
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
      chunk.size.must_be :<=, Harbor::BlockIO::block_size
      byte_size += chunk.size
    end

    byte_size.must_equal File.size(block_io_txt)

    FileUtils::rm(block_io_txt)
  end

  it "must iterate over a StringIO in chunks" do
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
      chunk.size.must_be :<=, Harbor::BlockIO::block_size
      byte_size += chunk.size
    end

    byte_size.must_equal File.size(block_io_txt)

    FileUtils::rm(block_io_txt)
  end

end