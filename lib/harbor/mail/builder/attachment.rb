class Harbor
  module Mail
    class Builder
      class Attachment
    
        attr_accessor :file, :name, :type, :headers
    
        def initialize(file, name, type, headers)
          @file = file
          @name = name
          @type = type
          @headers = headers
    
          # If we have a File/IO object, read it. Otherwise, we'll read it lazily.
          @body = file.read() if !file.kind_of?(Pathname) && file.respond_to?(:read)
        end
    
        def to_s
          @body ||= File.open(file.to_s(), "rb") { |f| f.read() }
    
          [@body].pack("m")
        end
    
        def name
          @name
        end
    
        def type
          @type ||= MIME::Types.type_for(@name.to_s).to_s
        end
    
        def inspect
          "#<MailBuilder::Attachment @file=#{@file.inspect}> @name=#{@name.inspect} @type=#{@type.inspect} @headers=#{@headers.inspect}"
        end
    
      end
    end
  end
end