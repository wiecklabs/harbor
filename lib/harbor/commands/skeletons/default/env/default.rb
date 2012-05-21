### Application's root path
# If you are developing a port you should use <@= app_class @>.root outside
# config / env files as it will be overwritten by other ports and main app
config.root = Pathname(__FILE__).dirname.parent

Harbor::View::path.unshift(config.root + "views")
Harbor::View::layouts.default("layouts/application")

### View helpers:
# Harbor will register all helpers from all applications on Harbor::ViewContext
# when it boots and this allow Harbor::ViewHelpers to find them. (config.helpers
# is an instance of it)
config.helpers.paths << config.root + "helpers/**/*.rb"

### Autoloader:
# Harbor will autoload your application code based on some conventions, but you
# can add other paths for your code to be found. (see Harbor::Autoloader for
# more information)
#
#   config.autoloader.paths << config.root + "some/path"

### Assets:
# Harbor uses Sprockets gem for serving and compiling assets and by default it
# will compile automatically development and test environments. For production
# you'll have to run "harbor assets" when deploying to compile and compress all
# assets from ports and application itself to the public folder.
#
# For more information check Harbor::Assets

config.assets.append_path config.root + "assets/javascripts"
config.assets.append_path config.root + "assets/stylesheets"

config.assets.compress = true

config.assets.precompiled_assets = %w( application.js application.css )

### Console setup:
# If you would like to use Pry (http://pry.github.com/) instead
# of IRB for your console, uncomment the configuration line below.
#
#  config.console = Harbor::Consoles::Pry
#
# Don't forget to add the following to your Gemfile and rebundle!
#
#  gem "pry"

### Template Caching:
# If you would like to enable Tilt (https://github.com/rtomayko/tilt) caching
# for all environments, uncomment the configuration line below and remove the
# same line from env/production.rb and env/stage.rb but be aware that you'll
# need to restart the app to see template changes while developing
#
#  Harbor::View.cache_templates!
