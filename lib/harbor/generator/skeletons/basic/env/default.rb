config.root = File.dirname(__FILE__).parent

Harbor::View::path.unshift(config.root + "views")
Harbor::View::layouts.default("layouts/application")