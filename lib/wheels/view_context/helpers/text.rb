##
# Text helper which provides common routines such as HTML escaping,
# or truncating (previewing) long pieces of text (such as photo captions).
##
module Wheels::ViewContext::Helpers::Text
  
  # Querystring escape +value+
  def q(value)
    # TODO: Remove external dependency!
    Rack::Utils::escape(value)
  end

  # HTML escape +value+
  def h(value)
    # TODO: Remove external dependency!
    Rack::Utils::escape_html(value)
  end
  
  # Truncate long text values
  # TODO: Test!
  def truncate(value, character_count = 30, trailing = "&hellip;")
    raise ArgumentError.new("Wheels::ViewContext::Helpers::Text#truncate[character_count] must be an Integer") unless character_count.is_a?(Integer)
    raise ArgumentError.new("Wheels::ViewContext::Helpers::Text#truncate[trailing] must be a String") unless trailing.is_a?(String)
    
    if value.nil?
      ""
    else
      string_form = value.to_s
      
      if string_form.empty?
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
  
  # Truncate long text values on the nearest word (rounding down if the size exceeds the character_count by more than 5%).
  # TODO: Test!
  def truncate_on_words(value, character_count, trailing = "&hellip;")
    word_count > size ? self.strip + '...' : self.split(/ /).first(word_count).join(' ').strip + ((self.split(/ /).size > word_count) ? '...' : '')
  end
  
end