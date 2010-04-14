##
# Generic I18n helpers
##
module Harbor::ViewContext::Helpers::I18n
  include R18n::Helpers
  def t(untranslated_string = nil)
    return R18n.get.t unless untranslated_string
    prepped_string = untranslated_string.gsub(".", "")
    path_prefix = view.instance_variable_get(:@filename).to_s.split(".")[0].split("/")
    translation_attempt = R18n.get.t[[path_prefix, prepped_string].flatten.compact.join(".")]
    return translation_attempt if translation_attempt.translated?
    
    until path_prefix.empty? || translation_attempt.translated?
      translation_attempt = R18n.get.t[[path_prefix, prepped_string].flatten.compact.join(".")]
      $services.get('logger').debug "localizing: #{untranslated_string.inspect} => R18n.get.t[#{[path_prefix, prepped_string].flatten.compact.join(".").inspect}] => #{translation_attempt.inspect}"
      
      path_prefix.shift
    end

    unless translation_attempt.translated?
      translation_attempt = R18n.get.t[prepped_string]
    end
    
    # if, after walking the path or by direct translation, we're STILL not translated, just return the key
    translation_attempt = untranslated_string unless translation_attempt.translated?
      
    $services.get('logger').debug "localizing: #{untranslated_string.inspect} => R18n.get.t[#{[path_prefix, prepped_string].flatten.compact.join(".").inspect}] => #{translation_attempt.inspect}"
    
    translation_attempt
  end

end