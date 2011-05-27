class Harbor::File::Checksum

  class FileNotFoundError < StandardError
    def initialize(path)
      super("File Not Found @ #{path}, cannot compute checksum")
    end
  end

  def self.generators
    @generators ||= Harbor::Container.new
  end

  def self.register(algorithm, generator_class, &block)
    generators.register("#{algorithm}_checksum_generator", generator_class, &block)
  end

  def initialize(algorithm, file)
    @algorithm = algorithm
    @file = file
  end

  def hex
    raise FileNotFoundError unless File.file?(@file.path)

    @generator ||= self.class.generators.get("#{@algorithm}_checksum_generator")
    @generator.compute(@file.path.to_s)
  end

  alias :to_s :hex

  def to_i
    hex.to_i(16)
  end

  def inspect
    "#<#{self.class}: \"#{to_s}\">"
  end

end

require "harbor/checksum/zlib"