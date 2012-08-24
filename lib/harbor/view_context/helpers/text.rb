##
# Text helper which provides common routines such as HTML escaping,
# or truncating (previewing) long pieces of text (such as photo captions).
##
module Harbor::ViewContext::Helpers::Text

  # Querystring escape +value+
  def q(value)
    # TODO: Remove external dependency!
    java.net.URLEncoder.encode value, ENCODED_CHARSET
  end

  # HTML escape +value+
  def h(value, default = nil)
    # TODO: Remove external dependency!
    Rack::Utils::escape_html(value.to_s.empty? ? default : value)
  end

  ##
  # Truncates an object to the specified character count, appending the specified
  # trailing text. The character count includes the length of the trailer. HTML entities
  # are counted as 1 character in trailing.
  # 
  #   truncate("Lorem ipsum dolor sit amet, consectetur") # => "Lorem ipsum dolor sit amet, c&hellip;"
  #   truncate("Lorem ipsum dolor sit amet, consectetur", 20) # => "Lorem ipsum dolor s&hellip;"
  #   truncate("Lorem ipsum dolor sit amet, consectetur", 20, "...") # => "Lorem ipsum dolor..."
  # 
  ##
  def truncate(value, character_count = 30, trailing = "&hellip;")
    unless character_count.is_a?(Integer)
      raise ArgumentError.new(
        "Harbor::ViewContext::Helpers::Text#truncate[character_count] must be an Integer, was #{character_count.inspect}"
      )
    end

    unless character_count > 0
      raise ArgumentError.new(
        "Harbor::ViewContext::Helpers::Text#truncate[character_count] must be greater than zero, was #{character_count.inspect}."
      )
    end

    unless trailing.is_a?(String)
      raise ArgumentError.new(
        "Harbor::ViewContext::Helpers::Text#truncate[trailing] must be a String, was #{trailing.inspect}"
      )
    end

    if value.nil?
      ""
    else
      string_form = value.to_s

      if string_form.nil? || string_form.empty?
        ""
      elsif string_form.size <= character_count
        string_form
      else
        # The Regexp match here is to determine if the +trailing+ value is an HTML entity code,
        # in which case we assume it's length is 1, or a textual value, in which case we use the
        # actual size.
        string_form[0, character_count - (trailing =~ /\&\w+\;/ ? 1 : trailing.size)] + trailing
      end
    end
  end

  ##
  # Truncates an object on the nearest word to the specified character count, appending the specified
  # trailing text. 
  # 
  #   truncate_on_words("Lorem ipsum dolor sit amet, consectetur") # => "Lorem ipsum dolor sit amet&hellip;"
  #   truncate_on_words("Lorem ipsum dolor sit amet, consectetur", 20) # => "Lorem ipsum dolor&hellip;"
  #   truncate_on_words("Lorem ipsum dolor sit amet, consectetur", 20, "...") # => "Lorem ipsum dolor..."
  # 
  # The truncation will always look backwards unless the forward word boundary is within 5% of the specified
  # character count. Thus:
  # 
  #   truncate_on_words("Lorem ipsum dolor sit amet, consectetur est.", 38) # => "Lorem ipsum dolor sit amet, consectetur..."
  # 
  ##
  def truncate_on_words(value, character_count = 30, trailing = "&hellip;")
    unless character_count.is_a?(Integer)
      raise ArgumentError.new(
        "Harbor::ViewContext::Helpers::Text#truncate_on_words[character_count] must be an Integer, was #{character_count.inspect}"
      )
    end

    unless character_count > 0
      raise ArgumentError.new(
        "Harbor::ViewContext::Helpers::Text#truncate_on_words[character_count] must be greater than zero, was #{character_count.inspect}."
      )
    end

    unless trailing.is_a?(String)
      raise ArgumentError.new(
        "Harbor::ViewContext::Helpers::Text#truncate_on_words[trailing] must be a String, was #{trailing.inspect}"
      )
    end

    return "" if value.nil?

    truncated_text = value.to_s.dup
    text_length = truncated_text.length

    return value if character_count >= text_length

    leftover = truncated_text.slice!(character_count, text_length)

    if (index = leftover.index(/\W|$/)) && index < (character_count * 0.05).ceil
      truncated_text << leftover.slice(0, index)
    else
      truncated_text = truncated_text[0, truncated_text.rindex(/\W/)]
    end

    # Remove any trailing punctuation.
    truncated_text.slice!(truncated_text.length - 1) if truncated_text[truncated_text.length - 1, 1] =~ /\W/

    truncated_text + trailing
  end

end