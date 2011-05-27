class Harbor::File::Checksum::QuickZipCrc

  def compute(path)
    if hex = `crc32 #{Shellwords.escape(path)}`.scan(/(?!0x)[0-9A-Z]{8}/)[0]
      hex.downcase
    else
      nil
    end
  end

end

warn "crc32 not found, please download and build from http://kremlor.net/projects/crc32/" unless (`which crc32` && $?.exitstatus == 0)

Harbor::File::Checksum.register(:pkzip, Harbor::File::Checksum::QuickZipCrc)