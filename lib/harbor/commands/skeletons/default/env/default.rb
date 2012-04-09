config.root = Pathname(__FILE__).dirname.parent

Harbor::View::path.unshift(config.root + "views")
Harbor::View::layouts.default("layouts/application")

### Assets:
# By default the application will serve static assets only for development and
# test environments. For production you'll have to run "harbor assets" when
# deploying to copy all assets from ports and application itself to the public
# folder.
# For more information about assets check Harbor::Assets (config.assets is an
# instance of it)
config.assets.serve_static = false
config.assets.paths.unshift(config.root + "assets")

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
