# Make use of Tilt (https://github.com/rtomayko/tilt) cache for compiled templates
Harbor::View.cache_templates!

Harbor.serve_public_files! config.root + 'public'
config.assets.compile = true

DB = Sequel.connect("jdbc:h2:mem:")

Sequel.extension :migration
Sequel::Migrator.run(DB, config.root + "db")