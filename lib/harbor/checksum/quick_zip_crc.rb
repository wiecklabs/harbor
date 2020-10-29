class Harbor::File::Checksum::QuickZipCrc

  def compute(path)
    raise ArgumentError, "Argument `path` refers to a file that doesn't exist: #{path}" unless File.file?(path)
    inputStream = java.io.BufferedInputStream.new(java.io.FileInputStream.new(path))
    crc = java.util.zip.CRC32.new

    until (data = inputStream.read) == -1 do
      crc.update(data)
    end

    crc.getValue.to_s(16).downcase
  end

end

Harbor::File::Checksum.register(:pkzip, Harbor::File::Checksum::QuickZipCrc)