module Harbor

  class Errors
  
    include Enumerable
  
    def initialize(errors = [])
      @errors = errors
    end
  
    def [](index)
      errors[index]
    end
  
    def <<(message)
      if message.is_a?(String)
        errors << message
      elsif message.is_a?(Enumerable)
        message.each do |error_message|
          errors << error_message
        end
      else
        errors << message
      end
    end
  
    def each
      errors.each do |error|
        yield error
      end
    end
  
    def size
      errors.size
    end
  
    def +(other)
      Errors.new((errors + other.errors).uniq)
    end

    protected
  
    def errors
      @errors
    end

  end

end