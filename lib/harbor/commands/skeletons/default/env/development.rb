config.reloader.enable!
config.assets.compile = true

Harbor.serve_public_files! config.root + 'public'
