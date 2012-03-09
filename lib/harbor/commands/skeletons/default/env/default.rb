config.root = Pathname(__FILE__).dirname.parent

Harbor::View::path.unshift(config.root + "views")
Harbor::View::layouts.default("layouts/application")

### Console setup:
# If you would like to use Pry (http://pry.github.com/) instead
# of IRB for your console, uncomment the configuration line below.
#
#  config.console = Harbor::Consoles::Pry
#
# Don't forget to add the following to your Gemfile and rebundle!
# 
#  gem "pry"