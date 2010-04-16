module Harbor::ViewContext::Helpers::Localization
  
  def t(untranslated_string, interpolation_string = nil)
    prepped_string = untranslated_string.gsub(".", "")
    path_prefix = view.instance_variable_get(:@filename).to_s

    request.locale.translate([path_prefix, prepped_string].flatten.compact.join("/"), interpolation_string)
  end

  def l(object, variation = :default)
    request.locale.localize(object, variation)
  end
  
end