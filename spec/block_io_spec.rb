require "pathname"
require Pathname(__FILE__).dirname + "helper"

describe "BlockIO" do
  
  before :all do
    @original_block_size = Wheels::BlockIO::BLOCK_SIZE
    $VERBOSE, verbose = nil, $VERBOSE
    Wheels::BlockIO::BLOCK_SIZE = 50
    $VERBOSE = verbose
  end
  
  after :all do
    $VERBOSE, verbose = nil, $VERBOSE
    Wheels::BlockIO::BLOCK_SIZE = @original_block_size
    $VERBOSE = verbose
  end
  
  it "should read a file" do
    io = Wheels::BlockIO.new(__FILE__)
    io.to_s.should =~ /should read a file/
  end

  it "should report the file size" do
    io = Wheels::BlockIO.new(__FILE__)
    io.size.should == File.size(__FILE__)
  end
  
  it "should iterate over a file in chunks" do
    meaningless_data = File.read(__FILE__)
    block_io_txt = Pathname(__FILE__).dirname + "samples" + "block_io.txt"
    
    File::open(block_io_txt, "w+") do |file|
      100.times do
        file << meaningless_data
        file << rand()
      end
    end
    
    byte_size = 0
    
    Wheels::BlockIO.new(block_io_txt).each do |chunk|
      chunk.size.should_not > Wheels::BlockIO::BLOCK_SIZE
      byte_size += chunk.size
    end
    
    byte_size.should == File.size(block_io_txt)
    
    FileUtils::rm(block_io_txt)
  end
  
end