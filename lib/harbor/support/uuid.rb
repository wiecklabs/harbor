if RUBY_PLATFORM == "java"
  require "java"
end

class UUID

  def self.generate
    if RUBY_PLATFORM == "java"
      java.util.UUID.randomUUID.toString
    else
     UUID.generate
    end
  end

end