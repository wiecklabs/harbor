#!/usr/bin/env jruby

require_relative "helper"

describe Harbor::ZippedIO do

  it "must create a simple zip file" do
    file = Harbor::File.new(Pathname(__FILE__).dirname + "samples" + "volcanoUPI_800x531.jpg")
    file2 = Harbor::File.new(Pathname(__FILE__).dirname + "application_spec.rb")
    zip = Harbor::ZippedIO.new([file, file2])
    size = zip.size
    -> do
      ::File.open("/tmp/ziptest_#{`uuidgen`.chomp}.zip", "w") do |file|
        zip.each do |data|
          file.write(data)
        end
      end
    end.wont_raise
  end

end
