module Wheels::ViewContext::Helpers
  autoload :Form, (Pathname(__FILE__).dirname + "helpers/form").to_s
  autoload :Text, (Pathname(__FILE__).dirname + "helpers/text").to_s
  autoload :Html, (Pathname(__FILE__).dirname + "helpers/html").to_s
end