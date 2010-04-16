module Harbor::ViewContext::Helpers
  autoload :Form, (Pathname(__FILE__).dirname + "helpers/form").to_s
  autoload :Text, (Pathname(__FILE__).dirname + "helpers/text").to_s
  autoload :Html, (Pathname(__FILE__).dirname + "helpers/html").to_s
  autoload :Url, (Pathname(__FILE__).dirname + "helpers/url").to_s
  autoload :Cache, (Pathname(__FILE__).dirname + "helpers/cache").to_s
  autoload :Localization, (Pathname(__FILE__).dirname + "helpers/localization").to_s
end