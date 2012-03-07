config.root = Pathname(__FILE__).dirname.parent

Harbor::View::path.unshift(config.root + "views")
Harbor::View::layouts.default("layouts/application")