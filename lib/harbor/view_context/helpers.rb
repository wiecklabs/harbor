<<<<<<< HEAD
module Harbor::ViewContext::Helpers
  autoload :Form, (Pathname(__FILE__).dirname + "helpers/form").to_s
  autoload :Text, (Pathname(__FILE__).dirname + "helpers/text").to_s
  autoload :Html, (Pathname(__FILE__).dirname + "helpers/html").to_s
  autoload :Url, (Pathname(__FILE__).dirname + "helpers/url").to_s
  autoload :Cache, (Pathname(__FILE__).dirname + "helpers/cache").to_s
end
=======
module Harbor::ViewContext::Helpers; end

require_relative "helpers/form"
require_relative "helpers/text"
require_relative "helpers/html"
require_relative "helpers/url"
require_relative "helpers/cache"
require_relative "helpers/assets"
>>>>>>> afcda6833a461947da81fee3e28965b762663c3e
