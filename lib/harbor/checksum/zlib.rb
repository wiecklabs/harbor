class Harbor::File::Checksum::ZlibCrc

  def compute(path)
    Zlib.crc32(::File.read(path)).to_s(16)
  end

end

Harbor::File::Checksum.register(:pkzip, Harbor::File::Checksum::ZlibCrc)